# bitra portrait fix: blob source for builders

## Source firmware

The OnePlus 8T on OxygenOS 14. The AxionAOSP OnePlus sm8250 tree records its blob source as `KB2005_14.0.0.603(EX01)`.

Public dumps: https://dumps.tadiphone.dev/dumps/oneplus/oneplus8t, on any `qssi-user-14-UKQ1.230924.001-*` branch. For example:
https://dumps.tadiphone.dev/dumps/oneplus/oneplus8t/-/tree/qssi-user-14-UKQ1.230924.001-1718270023955-release-keys--IN (KB2001 H.24)

I checked all five Android 14 OnePlus 8T dumps there. They contain byte-identical copies of these files, so any of them works.

## proprietary-files.txt (sm8250-common)

Replace the OnePlus 12 dualcam block. Source paths are from the OnePlus 8T dump (`vendor/`); destinations are bitra's `odm/`.

```
# Camera - ArcSoft dualcam from OnePlus 8T (OxygenOS 14, UKQ1.230924.001)
vendor/lib64/libarcsoft_dualcam_bokeh_api.so:odm/lib64/libarcsoft_dualcam_bokeh_api.so|1ab59342de1b31e8ed70335783a4f5f40653fb7d
vendor/lib64/libarcsoft_dualcam_refocus_left.so:odm/lib64/libarcsoft_dualcam_refocus_left.so|6b5d9bfe5251830fb54ac1f34b6e77339e32347e
vendor/lib64/libarcsoft_dualcam_refocus_preview.so:odm/lib64/libarcsoft_dualcam_refocus_preview.so|05f41d9ae49c1ddd25c7fbcb68e099b886a2f446|e76f27e392463562ab447595dc5cdd587a61c000
vendor/lib64/libarcsoft_dualcam_refocus_uw.so:odm/lib64/libarcsoft_dualcam_refocus_uw.so|6c290a3a3875f14e776f8df6d37670dec61e4086
vendor/lib/rfsa/adsp/libarcsoft_dualcam_refocus_skel.so:odm/lib/rfsa/adsp/libarcsoft_dualcam_refocus_skel.so|2d7abab9c8d72d5410df2b6ab7a4d151c8151926
```

`refocus_preview` has two hashes: stock before the fixup, then after it. The other four are used unmodified.

Drop `libarcsoft_qnnhtp.so` and `libarc.ion.so`. Nothing references them once the OnePlus 12 libs are gone.

## extract-files.py fixup (required)

```python
'odm/lib64/libarcsoft_dualcam_refocus_preview.so': blob_fixup()
    .clear_symbol_version('remote_handle_close')
    .clear_symbol_version('remote_handle_invoke')
    .clear_symbol_version('remote_handle_open')
    .clear_symbol_version('remote_register_buf_attr')
    .clear_symbol_version('remote_register_buf'),
```

Why: the stock OnePlus 8T `refocus_preview` requires those five symbols at version `SDSPRPC` of `libcdsprpc.so`. bitra's realme `libcdsprpc.so` exports them but defines no symbol versions, so the unpatched lib fails to load. The OnePlus sm8250 tree applies exactly this fixup (`extract-files.py`, AxionAOSP-devices/android_device_oneplus_sm8250-common). In the binary it changes 5 versym entries from 4 to 1.

## Android.bp

`refocus_preview` has `DT_NEEDED libcdsprpc.so`. Re-running `setup-makefiles` should add `libcdsprpc` to its `shared_libs`. If it doesn't, Soong's `check_elf_file` fails at build time.

## Tested

On bitra (RMX3370), DerpFest 16.2 on the sm8250-common `lineage-23.2` trees: front and rear portrait both work.

Previous attempts, for reference:

| Libraries | Front portrait | Rear portrait | Failure |
|---|---|---|---|
| OnePlus 12 set | crashes | crashes | ALGO_INTERFACE watchdog abort; the missing `libarc_htp_driver_skel.so` makes `ARC_DCIR_Init` hang |
| Stock realme set | works | crashes | SIGSEGV in `refocus_left` |

Full analysis: https://github.com/SM8250-Common/android_device_realme_sm8250-common/issues/2
