#!/bin/bash
MODE=$1

# Mechanism Lockfile untuk mencegah eksekusi beruntun
LOCKFILE="/tmp/power_backend.lock"
exec 200>"$LOCKFILE"
flock -n 200 || exit 1

STATE_DIR="/tmp/power_state_backup"
mkdir -p "$STATE_DIR"

BL_DEV=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n1)

if [ "$MODE" = "on" ]; then
    # 1. Backup Bluetooth
    if /usr/sbin/rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
        echo "blocked" > "$STATE_DIR/bt_state"
    else
        echo "unblocked" > "$STATE_DIR/bt_state"
    fi

    # 2. Backup Wi-Fi Power Save
    iwdev=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}' | head -n1)
    if [ -n "$iwdev" ]; then
        echo "$iwdev" > "$STATE_DIR/wifi_iface"
        wifi_ps=$(iw dev "$iwdev" get power_save 2>/dev/null | awk '{print $3}')
        echo "${wifi_ps:-off}" > "$STATE_DIR/wifi_ps"
    fi

    # 3. Backup TLP
    if systemctl is-active --quiet tlp 2>/dev/null; then
        echo "active" > "$STATE_DIR/tlp_state"
    else
        echo "inactive" > "$STATE_DIR/tlp_state"
    fi

    # 4. Backup Audio Power Save
    if [ -f /sys/module/snd_hda_intel/parameters/power_save ]; then
        cat /sys/module/snd_hda_intel/parameters/power_save > "$STATE_DIR/audio_ps"
        echo 1 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null
    fi

    # 5. Backup & Set Brightness (Hanya pangkas jika > 40%)
    if [ -n "$BL_DEV" ] && [ -f "$BL_DEV/brightness" ] && [ -f "$BL_DEV/max_brightness" ]; then
        curr_br=$(cat "$BL_DEV/brightness")
        max_br=$(cat "$BL_DEV/max_brightness")
        echo "$curr_br" > "$STATE_DIR/brightness_val"
        target_br=$(( max_br * 40 / 100 ))
        
        if [ "$curr_br" -gt "$target_br" ]; then
            echo "$target_br" > "$BL_DEV/brightness" 2>/dev/null
        fi
    fi

    # --- EKSEKUSI MODE ON ---
    [ -f /sys/devices/system/cpu/cpufreq/boost ] && echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
    for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -f "$g" ] && echo "powersave" > "$g" 2>/dev/null
    done
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [ -f "$epp" ] && echo "power" > "$epp" 2>/dev/null || echo "balance_power" > "$epp" 2>/dev/null
    done
    [ -f /sys/module/pcie_aspm/parameters/policy ] && echo "powersupersave" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null
    
    rfkill block bluetooth 2>/dev/null
    [ -n "$iwdev" ] && iw dev "$iwdev" set power_save on 2>/dev/null
    echo 3000 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null
    powertop --auto-tune >/dev/null 2>&1
    systemctl start tlp >/dev/null 2>&1
    echo "SUCCESS_ON"

elif [ "$MODE" = "off" ]; then
    # --- EKSEKUSI MODE OFF ---
    [ -f /sys/devices/system/cpu/cpufreq/boost ] && echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null
    for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [ -f "$g" ] && echo "performance" > "$g" 2>/dev/null
    done
    for epp in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
        [ -f "$epp" ] && echo "performance" > "$epp" 2>/dev/null
    done
    [ -f /sys/module/pcie_aspm/parameters/policy ] && echo "default" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null
    echo 500 > /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null

    # --- RESTORE PREVIOUS STATES ---
    if [ -n "$BL_DEV" ] && [ -f "$STATE_DIR/brightness_val" ]; then
        prev_br=$(cat "$STATE_DIR/brightness_val")
        echo "$prev_br" > "$BL_DEV/brightness" 2>/dev/null
    fi

    if [ -f "$STATE_DIR/audio_ps" ] && [ -f /sys/module/snd_hda_intel/parameters/power_save ]; then
        cat "$STATE_DIR/audio_ps" > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null
    fi

    if [ -f "$STATE_DIR/bt_state" ]; then
        [ "$(cat "$STATE_DIR/bt_state")" = "unblocked" ] && rfkill unblock bluetooth 2>/dev/null
    fi

    if [ -f "$STATE_DIR/wifi_iface" ] && [ -f "$STATE_DIR/wifi_ps" ]; then
        iwdev=$(cat "$STATE_DIR/wifi_iface")
        wifi_ps=$(cat "$STATE_DIR/wifi_ps")
        [ -n "$iwdev" ] && iw dev "$iwdev" set power_save "$wifi_ps" 2>/dev/null
    fi

    if [ -f "$STATE_DIR/tlp_state" ]; then
        [ "$(cat "$STATE_DIR/tlp_state")" = "inactive" ] && systemctl stop tlp >/dev/null 2>&1
    else
        systemctl stop tlp >/dev/null 2>&1
    fi

    rm -rf "$STATE_DIR"
    echo "SUCCESS_OFF"
fi
