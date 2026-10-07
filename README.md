# bitra portrait fix

Fixes the **OplusCamera portrait mode crash** on custom ROMs for the **realme GT Neo 2 (bitra, RMX3370)**, Snapdragon 870.

On ROMs built from the SM8250-Common trees, the camera closes about 20 seconds after you switch to Portrait. It happens on both cameras, and you don't need to take a photo for it to crash. These five OnePlus 8T ArcSoft libraries fix it: verified with front and rear portrait working on DerpFest 16.2.

## Cause

The ROMs ship OnePlus 12 ArcSoft dualcam libraries. Their depth engine (`ARC_DCIR_Init`) runs part of its work on the DSP through QNN-HTP and asks the cDSP to load `libarc_htp_driver_skel.so`. That file doesn't exist: the Snapdragon 870 has an HTA, not the HTP of newer Snapdragons.

What happens on the phone:
1. Init fails, and `ARC_DCIR_Uninit` hangs.
2. After 20 seconds, Oplus's `ALGO_INTERFACE` watchdog in `libAlgoProcess.so` aborts the camera:
   ```
   E APS_CORE: ... thirdPartyAlgoTimerFunc() timerType: 0 timeout, ... raise SIGABRT, third party algo (aps_algo_bokeh) error!!!
   E com.oplus.camera: ... remote_handle_open_domain: dynamic loading failed for file:///libarc_htp_driver_skel.so?...
   ```

Libraries from the OnePlus 8T use the same chip family, so they use HVX and HTA, and they load fine.

| Dualcam libraries | Front portrait | Rear portrait | Failure |
|---|---|---|---|
| OnePlus 12 (current trees) | crash | crash | watchdog abort, init hang (missing HTP driver) |
| Stock realme | works | crash | SIGSEGV in `refocus_left` |
| Stock + OnePlus 12 `refocus_left` | crash | crash | same init hang |
| **OnePlus 8T (this repo)** | **works** | **works** | — |

Full analysis: [SM8250-Common/android_device_realme_sm8250-common#2](https://github.com/SM8250-Common/android_device_realme_sm8250-common/issues/2)

## Files

| File | Install path on bitra | SHA-1 |
|---|---|---|
| `libarcsoft_dualcam_bokeh_api.so` | `/odm/lib64/` | `1ab59342de1b31e8ed70335783a4f5f40653fb7d` |
| `libarcsoft_dualcam_refocus_left.so` | `/odm/lib64/` | `6b5d9bfe5251830fb54ac1f34b6e77339e32347e` |
| `libarcsoft_dualcam_refocus_preview.so` | `/odm/lib64/` | `e76f27e392463562ab447595dc5cdd587a61c000` |
| `libarcsoft_dualcam_refocus_uw.so` | `/odm/lib64/` | `6c290a3a3875f14e776f8df6d37670dec61e4086` |
| `libarcsoft_dualcam_refocus_skel.so` (DSP side) | `/odm/lib/rfsa/adsp/` | `2d7abab9c8d72d5410df2b6ab7a4d151c8151926` |

- **Source:** OnePlus 8T, OxygenOS 14 (`UKQ1.230924.001`). The same files are in the public dumps at [dumps/oneplus/oneplus8t](https://dumps.tadiphone.dev/dumps/oneplus/oneplus8t), and in [AxionAOSP-devices/android_vendor_oneplus_sm8250-common](https://github.com/AxionAOSP-devices/android_vendor_oneplus_sm8250-common) @ `59a046d`.
- **`refocus_preview` is the stock file with one fixup applied.** Five symbol versions are cleared (`clear_symbol_version`) because bitra's `libcdsprpc.so` has no `SDSPRPC` version tags. The other four files are stock, unmodified.
- **Keep the set together.** The host libraries and the DSP skel must match.

## For ROM builders

See **[BUILDER.md](BUILDER.md)**. It has the `proprietary-files.txt` block with pinned hashes, the required `extract-files.py` fixup, and the `Android.bp` note.

## For users on an affected ROM (Magisk module)

`magisk/` contains a module that bind-mounts these five files over the ROM's copies at boot, keeping the original SELinux labels. Grab the zip from [Releases](../../releases), or build it with `magisk/build.sh`.

- It installs on bitra only.
- Remove it in Magisk, then reboot, to undo it.
- **Status:** tested on bitra (DerpFest 16.2, Magisk 31.0). The module installs, all five bind mounts come up with the original SELinux label (`same_process_hal_file`), the camera app maps the module's copies, and rear and front Portrait photos save without crashing. That ROM already shipped these libs, so a ROM that still has the OnePlus 12 libs hasn't been tested yet. Reports welcome.
- **Known:** on bitra the cDSP refuses to load `libarcsoft_dualcam_refocus_skel.so` (`Streaming Hash Finalize error`). The depth engine still initialises (`ARCDCR_Init() finished! (0)`) and portrait works without the DSP. This is the same with or without the module, because the files are identical.
- Don't add OplusCamera to the Magisk DenyList, because that would unmount the fix for the camera.

## Notice

The `.so` files are proprietary binaries from OnePlus and ArcSoft, redistributed for interoperability, as custom ROM vendor repositories commonly do. All rights remain with their owners. The scripts and docs here may be used freely.
