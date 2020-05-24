#!/bin/bash

# Patches magisk and other items into updater-script on selected rom 

if [ $# -lt 6 ]; then
  echo "USAGE: [ROM FILE] [ROM FOLDER OUT] [MAGISK VERSION] [DEVICE] [BUILD_DIR] [MAGISK_IN_BUILD]"
  exit 1
fi

rom_file_in=$1
rom_folder_out=$2
magisk_version=$3
device_name=$4
building_dir=$5
magisk_in_build=$6

# Error checking

if [[ $rom_file_in != *.zip ]]; then
  echo "Error - ROM FILE is invalid"
  exit 2
fi

if [ ! -f $rom_file_in ]; then
  echo "Error - ROM FILE doesn't exist"
  exit 3
fi

if [ ! -d $rom_folder_out ]; then
  echo "Error - ROM FOLDER OUT doesn't exist"
  exit 4
fi

file_name=$(basename $rom_file_in)
WORK_DIR=`mktemp -d`

# Extract zip to folder
unzip $rom_file_in -d $WORK_DIR > /dev/null 2>&1

# Add magisk to updater script
update_script="$WORK_DIR/META-INF/com/google/android/updater-script"

if [ $magisk_in_build -eq 1 ]; then

  echo "Adding magisk to $file_name"

cat <<EOT >> $update_script
ui_print("-- Installing: Magisk");
package_extract_dir("META-INF/ADD-ONS/Magisk", "/tmp/Magisk");
run_program("/sbin/busybox", "unzip", "/tmp/Magisk/Magisk.zip", "META-INF/com/google/android/*", "-d", "/tmp/Magisk");
run_program("/sbin/busybox", "sh", "/tmp/Magisk/META-INF/com/google/android/update-binary", "dummy", "1", "/tmp/Magisk/Magisk.zip");
delete_recursive("/tmp/Magisk");
EOT

  # Make magisk addon directory
  magisk_dir=$WORK_DIR/META-INF/ADD-ONS/Magisk
  mkdir -p "$magisk_dir"

  # Get latest magisk version
  magisk_url="https://github.com/topjohnwu/Magisk/releases/download/v$magisk_version/Magisk-v$magisk_version.zip"
  wget $magisk_url -O $magisk_dir/Magisk.zip > /dev/null 2>&1

fi

if [ $LIBEXYNOS_CAMERA -eq 1 ]; then
cat <<EOT2 >> $update_script
ui_print("-- Installing: libexynoscamera3.so");
package_extract_dir("META-INF/ADD-ONS/libexynoscamera3", "/tmp/libexynoscamera3");
mount("ext4", "EMMC", "/dev/block/platform/11120000.ufs/by-name/VENDOR", "/vendor");
run_program("/sbin/busybox", "mv", "/tmp/libexynoscamera3/libexynoscamera3.so", "/vendor/lib/libexynoscamera3.so");
run_program("/sbin/busybox", "umount", "/vendor");
delete_recursive("/tmp/libexynoscamera3");
EOT2

# Make libexynos addon directory
libexynoscamera_dir=$WORK_DIR/META-INF/ADD-ONS/libexynoscamera3
mkdir -p "$libexynoscamera_dir"

# Copy device lib to addon directory
cp $building_dir/supplements/libexynoscamera3/libexynoscamera3-$device_name.so $libexynoscamera_dir/libexynoscamera3.so
fi

# Zip folder to output directory
rm -rf "$rom_folder_out/$file_name"
cd $WORK_DIR/
zip -r "$rom_folder_out/$file_name" . > /dev/null 2>&1
echo "File saved to '$rom_folder_out/$file_name'"

# Delete temporary directory
rm -rf $WORK_DIR
