#!/system/bin/sh
# Bind-mount the OnePlus 8 ArcSoft dualcam libs over the ROM's copies in /odm,
# reusing each original file's SELinux label so the camera can still load them.
MODDIR=${0%/*}
over() {
  src="$MODDIR/files/$1"; dst="$2/$1"
  [ -f "$src" ] && [ -f "$dst" ] || return 0
  ctx=$(ls -Z "$dst" | awk '{print $1}')
  [ -n "$ctx" ] && chcon "$ctx" "$src"
  mount -o bind "$src" "$dst"
}
for f in bokeh_api refocus_left refocus_preview refocus_uw; do
  over "libarcsoft_dualcam_$f.so" /odm/lib64
done
over libarcsoft_dualcam_refocus_skel.so /odm/lib/rfsa/adsp
