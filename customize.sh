lineage_platform_res_path="framework/org.lineageos.platform-res.apk"
tools_path="$MODPATH/tools"

chmod -R 755 "$tools_path"
alias apktool='ANDROID_DATA="$TMPDIR" ANDROID_ROOT=/system LD_LIBRARY_PATH=/system/lib dalvikvm -cp "$tools_path/apktool_2.5.0-dexed.jar" -Djava.io.tmpdir="$TMPDIR" -Dsun.arch.data.model=64 brut.apktool.Main' # -q
alias xmlstarlet='$tools_path/xmlstarlet'
alias zipalign='$tools_path/zipalign'

check_requirements() {
  ui_print "- Checking requirements"

  if [ -z "$(getprop ro.lineage.build.version)" ]; then
    ui_print "- Only for LineageOS!"
    abort
  fi

  if [ "$IS64BIT" = false ]; then
    ui_print "- Only for 64bit architecture!"
    abort
  fi
}

prepare() {
  if $BOOTMODE; then
    ui_print "- Magisk installation"
    system_path="$(magisk --path)/.magisk/mirror/system"
  else
    ui_print "- Recovery installation"
    system_path=$(dirname "$(find / -mindepth 2 -maxdepth 3 -path "*system/build.prop"|head -1)")
  fi
}

apktool_if() {
  apktool if "$1"
}

apktool_d() {
  apktool d -o "$2" -s "$1"
  test $? != 0 && abort "Decoding APK resources failed. Aborting..."
}

apktool_b() {
  apktool b -a "$MODPATH/tools/aapt" -c -o "$2" "$1"
  test $? != 0 && abort "Rebuilding APK resources failed. Aborting..."
}

add_sony_platform_signature() {
  ui_print "- Adding Sony platform signature"

  #apktool_if "$system_path/framework-res.apk"
  #apktool_if "$system_path/$lineage_platform_res_path"

  local resout="$TMPDIR/resout"

  apktool_d "$system_path/$lineage_platform_res_path" "$resout"

  xmlstarlet ed -L -S \
    --subnode "/resources/array[@name='config_vendorPlatformSignatures']" \
    --type elem -n item \
    -v "3082038e30820276a003020102020103300d06092a864886f70d01010505003065310b3009060355040613025345312f302d060355040a1326536f6e79204572696373736f6e204d6f62696c6520436f6d6d756e69636174696f6e73204142312530230603550403141c536f6e795f4572696373736f6e5f455f43415f4c6976655f38363466301e170d3030303130313134313031385a170d3335303130313134313031385a3073310b3009060355040613025345312f302d060355040a1326536f6e79204572696373736f6e204d6f62696c6520436f6d6d756e69636174696f6e73204142313330310603550403142a536f6e795f4572696373736f6e5f455f506c6174666f726d5f5369676e696e675f4c6976655f3836346630820122300d06092a864886f70d01010105000382010f003082010a0282010100adf1ce025fb98eaad8073b1a398b5972c55f13b28b2bdd1e86186ad6d7f1c5c33b7ee9db826eaa6d57478abdf4195cd8d7b6eb9b579daed354c082072cddf9f21b6f8516ca8af009f776fe354505f8a229cb43e012435cea542c0c6e64d9a962ee09992aa3d60a1f31a978535a4859f96b6b06d6b9ed64c38dbf03fe62838d3744293599aa3a09d20faf5526b577f5d1dc3271e6b02029c606b962240377aa934b32f8f0be3c216cc5597dea26f6b0c4c1b22a704d266542359d00b7926d0947d11291dd201933d4ed9b31a103a84b8049748e5c38448ecce4bc3184cec8ece51b18a4a5557e5a0d4fdd8dc2c2f07d2113b434f678ebd2abf87c6dbefb79acf90203010001a33b3039300f0603551d130101ff04053003020100300e0603551d0f0101ff04040302078030160603551d250101ff040c300a06082b06010505070303300d06092a864886f70d0101050500038201010002a79ebf73014a309cd1a583690e16127ee6adb801474fb810c3f5aecbbc80783de2113386e9ad7dd62929ac516fc9e13aaf6532c114b8333856b915071c2977f1dd395c8f70283ab5f6109bda92bcb5306243e432aa5d902d29f867f84d54e69447af43db9ea215ca4fe354d42e3da59e0c44d727bf0864b58f62ac71f2d69db7ffa9338f23467c6d81cf75314e9f8e1685d31ebb989fda78168fba962ea7246bceca13b1e1deff1f12e3f787941b3e73412f3d23d661ae0c05edeef415a3f34dc3739950eaf22f111ad2e0c1f2224a5d79aaab4a3e3eb5bdd74dc64135aff386809afc15a985857f8882c41a249466a5c5e3466df643ed29c9b032988f0504" \
    "$resout/res/values/arrays.xml"

  apktool_b "$resout" "$TMPDIR/res.apk"

  zipalign 4 "$TMPDIR/res.apk" "$MODPATH/system/$lineage_platform_res_path"
}

ota_survival() {
  ui_print "- Creating OTA survival service"
  cp -f "$ZIPFILE" "$MODPATH/install.zip"
  sed -i "s|previous_md5sum_tmp|previous_md5sum=$(md5sum "$MODPATH/system/$lineage_platform_res_path"|cut -d ' ' -f1)|" "$MODPATH/service.sh"
}

check_requirements
prepare
add_sony_platform_signature
ota_survival
