# Understanding the ZFS ZIO Pipeline

This document explains how **ZIO** (ZFS I/O) objects move through the **pipeline** in OpenZFS. Primary code: [`module/zfs/zio.c`](../module/zfs/zio.c), stage definitions: [`include/sys/zio_impl.h`](../include/sys/zio_impl.h).

## What is a ZIO?

A **zio** (`zio_t`) is one unit of work: a read, write, free, trim, ioctl, etc. It carries:

- **Where**: `io_vd` (vdev), `io_offset`, `io_size`, spa, txg  
- **What**: `io_type`, `io_abd` (buffer), optional `io_bp` (block pointer)  
- **Result**: `io_error`  
- **Tree**: **parent** zios and **child** zios (e.g. RAID-Z parent → one child per disk column)

The **pipeline** is an ordered set of **stages**. Each zio has `io_pipeline` (which stages apply) and `io_stage` (how far it has progressed).

## Stage encoding

Stages are **powers of two** (single bits). `io_pipeline` is a bitmask of enabled stages. Execution order is **increasing bit order** (conceptually left-to-right in the table below).

| Bit | Stage | Typical role |
|-----|--------|----------------|
| OPEN | (initial; not in `zio_pipeline[]` as a function) | ZIO created |
| READ_BP_INIT | Interpret BP for reads | |
| WRITE_BP_INIT | Set up BP for writes | |
| FREE_BP_INIT | Free path | |
| ISSUE_ASYNC | Async write issue | |
| WRITE_COMPRESS / ENCRYPT | Transform data | |
| CHECKSUM_GENERATE | Write checksum | |
| NOP_WRITE / DDT_* / GANG_* / DVA_* | Dedup, gang blocks, allocate/free DVAs | |
| READY | Final prep before vdev I/O | |
| **VDEV_IO_START** | **Issue I/O to vdev tree** (mirror/RAID-Z/disk) | |
| **VDEV_IO_DONE** | **I/O completed** (all children done for parents) | |
| **VDEV_IO_ASSESS** | Errors, retry policy, interlock | |
| CHECKSUM_VERIFY | Read verification | |
| DONE | Callbacks, notify parents, destroy or wake waiter | |

Full enum: `enum zio_stage` in `zio_impl.h`.

## How execution works: `zio_execute` / `__zio_execute`

1. **`zio_wait(zio)`** or **`zio_nowait(zio)`** eventually calls **`zio_execute(zio)`** → **`__zio_execute(zio)`**.

2. **Loop** until `io_stage` reaches **DONE**:
   - Start from current `io_stage`.
   - **Advance** to the **next** stage that has a bit set in `io_pipeline` (shift left until a pipeline bit is hit).
   - Set `io_stage` to that stage.
   - Call **`zio_pipeline[highbit64(stage) - 1](zio)`** — the handler for that stage.

3. **Handler return value**:
   - **Non-NULL zio**: continue the loop with that zio (usually the same zio).
   - **NULL**: **stop** this run. The zio is either **waiting** (e.g. async disk I/O) or **finished** for now.

So the pipeline is **not** one big synchronous function: **VDEV_IO_START** often **returns NULL** after submitting work; completion **re-enters** the pipeline later via **`zio_interrupt()`** → taskq → **`zio_execute()`**.

## The three vdev stages (most important for disk I/O)

### `zio_vdev_io_start`

- Walks the **vdev** tree: mirror, RAID-Z, or **leaf** (file/disk).
- **Leaf** (disk): may go through **vdev queue**, then **`vdev_op_io_start`** (e.g. **`vdev_disk_io_start`** → `submit_bio`).
- **Interior** (RAID-Z/mirror): creates **child zios** (`zio_vdev_child_io` + `zio_nowait`) and may call **`zio_execute(parent)`** so the parent continues only after children complete.
- Returns **NULL** when actual I/O is **asynchronous** (bios in flight).

### `zio_vdev_io_done`

- Runs when the zio reaches the **done** side of vdev I/O (for a leaf, after **bios completed** and **`zio_interrupt`** advanced the stage).
- Waits for **vdev children** if any.
- Leaf: queue accounting, cache, **`vdev_op_io_done`** (e.g. disk media check).
- Returns the zio → pipeline proceeds to **ASSESS**.

### `zio_vdev_io_assess`

- Frees RAID-Z map (`io_vsd`), fault injection, **retry** for specific **non-leaf** cases (`vd == NULL`), **ENXIO** handling, **interlock pipeline** on error (`ZIO_INTERLOCK_PIPELINE` skips checksum/normal done path).
- **`io_physdone`** for leaf children.
- Then **CHECKSUM_VERIFY** (reads) and **DONE**.

## Bio completion → next pipeline stage (leaf write)

Rough sequence for a **leaf** write:

1. **`zio_vdev_io_start`** → **`submit_bio`** → handler returns **NULL** (`io_stage` left at **VDEV_IO_START**).
2. Bio completes → **`vdev_disk_physio_completion`** → **`zio_delay_interrupt(zio)`** → **`zio_interrupt(zio)`** → **interrupt taskq** runs **`zio_execute(zio)`**.
3. **`__zio_execute`**: from **VDEV_IO_START**, next stage bit is **VDEV_IO_DONE** → **`zio_vdev_io_done`**.
4. Then **VDEV_IO_ASSESS**, then remaining stages (e.g. **DONE**).

Parents (e.g. **RAID-Z**) only reach **VDEV_IO_DONE** after **all child zios** have finished **DONE** (parent/child linkage via **`zio_notify_parent`**).

## Parent / child zios

- **Child** zios use **`ZIO_VDEV_CHILD_PIPELINE`**: **VDEV_IO_START → VDEV_IO_DONE → DONE** (no full write pipeline on the child).
- Child errors are usually handled in **`io_done`** callbacks (e.g. **`vdev_raidz_child_done`**); the parent aggregates in **`vdev_raidz_io_done`**.
- When the last child completes, the **parent** is woken and continues its own pipeline.

## Example pipelines (macros in `zio_impl.h`)

- **`ZIO_READ_PIPELINE`**: READ_BP_INIT … READY → vdev three stages → CHECKSUM_VERIFY → DONE  
- **`ZIO_WRITE_PIPELINE`**: WRITE_BP_INIT, compress/encrypt, DVA allocate, … READY → vdev three stages → ISSUE_ASYNC, CHECKSUM_GENERATE → DONE  
- **`ZIO_VDEV_CHILD_PIPELINE`**: READY → VDEV_IO_START/DONE/ASSESS → DONE (leaf column I/O)

## Key files

| Piece | Location |
|-------|----------|
| Stage enum, pipeline macros | `include/sys/zio_impl.h` |
| `zio_pipeline[]`, `__zio_execute`, stage functions | `module/zfs/zio.c` |
| Disk submit/complete | `module/os/linux/zfs/vdev_disk.c` |
| RAID-Z parent/child | `module/zfs/vdev_raidz.c` |

## Mental model

1. **ZIO** = one node in an **I/O tree** driven by a **bitmask pipeline**.  
2. **Async boundary** = **VDEV_IO_START** returning NULL; **zio_interrupt** resumes at **VDEV_IO_DONE**.  
3. **RAID-Z/mirror** = **parent zio** + **child zios**; parent’s vdev **done/assess** run **after all children** complete.  
4. **Errors** are finalized in **io_done** / **assess** and may switch to **interlock** pipeline for checksum/done shortcuts.

This is an overview; gang blocks, dedup, ZIL, and scrub use additional stages and flags.
