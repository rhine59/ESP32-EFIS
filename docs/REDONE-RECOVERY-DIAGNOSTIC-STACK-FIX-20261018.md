# RedOne recovery diagnostic stack overflow — fix and verification

**18 October 2026 — source FIXED, firmware BUILT, physical retest NOT YET PERFORMED.**

The single-board factory recovery test exposed a stack overflow after the USB `test` diagnostic command printed its JSON. The factory recovery `sdkconfig` sets `CONFIG_ESP_MAIN_TASK_STACK_SIZE=3584`, but `recovery_diagnostics_print()` previously declared `char report[4096]` on that main task stack, in addition to normal call frames and other locals. This exceeded the stack budget.

The function now allocates the 4096-byte diagnostic buffer using `heap_caps_malloc(..., MALLOC_CAP_8BIT)`, checks allocation failure, prints the same JSON, and frees the buffer. The HTTP diagnostics path already used heap allocation. The fix does not change boot selection, diagnostics schema, NVS, OTA or network authorization.

The recovery firmware builds successfully with pinned ESP-IDF 5.4.4 and fits the 1 MiB factory partition: image size `0xc6de0` bytes. The newly built local image SHA-256 is `cf5e7172e77fb8704179f1eacf1692d75882bd7fc81f67ad431f97f1af477648`. Two new source regression tests pass; 46 boot-recovery-lab tests also pass.

**Deployment remains pending.** The corrected image is only in the local build directory. The physical board is currently booting OTA A and still contains the original recovery image. Replacing its factory recovery partition is a physical flash write with risk of losing the only known recovery path. It requires a fresh backup and separate explicit approval, and must be performed with an exact partition-only write and readback comparison. Do not use generic `idf.py flash` or modify OTA metadata, bootloader, partition table, NVS or eFuses.
