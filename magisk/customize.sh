# Only for realme GT Neo 2 (bitra) ROMs that ship ArcSoft dualcam libs in /odm
DEV="$(getprop ro.product.device) $(getprop ro.lineage.device) $(getprop ro.product.vendor.device)"
case "$DEV" in
  *bitra*|*RE5473*|*RE879AL1*) ui_print "- Device: realme GT Neo 2 (bitra)" ;;
  *) abort "! This module is only for the realme GT Neo 2 (bitra). Found: $DEV" ;;
esac
[ -f /odm/lib64/libarcsoft_dualcam_refocus_left.so ] || abort "! ArcSoft dualcam libs not found in /odm - this ROM is not supported"
CUR=$(sha1sum /odm/lib64/libarcsoft_dualcam_refocus_left.so | cut -c1-8)
case "$CUR" in
  6b5d9bfe) ui_print "- Note: this ROM already ships the OnePlus 8 libs; the module changes nothing here" ;;
  af5108dd) ui_print "- Found OnePlus 12 dualcam libs (cause of the portrait crash): will replace" ;;
  *)        ui_print "- Found other dualcam libs ($CUR): will replace" ;;
esac
set_perm_recursive "$MODPATH/files" 0 0 0755 0644
ui_print "- Reboot, then test Portrait on rear and front cameras"
