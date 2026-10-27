#!/bin/bash

EPP_VAL=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)
GOV_VAL=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

if [ "$EPP_VAL" = "power" ] || [ "$EPP_VAL" = "balance_power" ] || [ "$GOV_VAL" = "powersave" ]; then
    STATUS_TEXT="Status Saat Ini: [ HEMAT DAYA / ON ]"
    INIT_ON="TRUE"
    INIT_OFF="FALSE"
else
    STATUS_TEXT="Status Saat Ini: [ PERFORMA NORMAL / OFF ]"
    INIT_ON="FALSE"
    INIT_OFF="TRUE"
fi

CHOICE=$(zenity --list --radiolist \
  --title="Penghemat Daya System" \
  --text="$STATUS_TEXT\n\nPilih mode manajemen daya:" \
  --column="Pilih" --column="Mode" \
  $INIT_ON "ON (Hemat Daya)" \
  $INIT_OFF "OFF (Performa Normal)" \
  --width=380 --height=240 2>/dev/null)

if [ -z "$CHOICE" ]; then
    exit 0
fi

if [ "$CHOICE" = "ON (Hemat Daya)" ]; then
    sudo /usr/local/bin/power-backend.sh on
    notify-send 'Penghemat Daya' 'Mode Hemat Daya AKTIF!' -i battery-good 2>/dev/null
elif [ "$CHOICE" = "OFF (Performa Normal)" ]; then
    sudo /usr/local/bin/power-backend.sh off
    notify-send 'Penghemat Daya' 'Mode Performa Normal AKTIF!' -i battery-full 2>/dev/null
fi
