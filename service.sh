previous_md5sum_tmp

if [[ $previous_md5sum != `md5sum $(magisk --path)/.magisk/mirror/system/framework/org.lineageos.platform-res.apk|cut -d ' ' -f1` ]]; then
  magisk --install-module /data/adb/modules/sony-smartcharger/install.zip
else
  exit
fi
