#!/usr/bin/env dash

__write() {
    cat - | sudo tee "${1}" >/dev/null
}

__sleep() {
    # REF:
    #   https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate#Changing_suspend_method
    #   $ man systemd-sleep.conf

    local _dir="/etc/systemd/sleep.conf.d"
    sudo mkdir -p "${_dir}"
    cat <<STOP | __write "${_dir}/sleep-s3.conf"
[Sleep]
MemorySleepMode=deep s2idle shallow
STOP
}

__thinkfan() {
    paru -S --needed --noconfirm -- thinkfan

    local _kmod="thinkpad_acpi"

    # guarantee one full load'g of the kernel-module
    if lsmod | grep -q "${_kmod}"; then
        sudo modprobe -r "${_kmod}"
    fi
    sudo modprobe "${_kmod}"

    sudo cp "./t480-thinkfan.yaml" "/etc/thinkfan.yaml"
    systemctl enable --now -- thinkfan.service
}

__tlp() {
    local _dir="/etc/tlp.d/"

    __platform() {
        # REF:
        #   https://linrunner.de/tlp/settings/platform.html

        sudo tee "${_dir}/platform.conf" <<STOP >/dev/null
MEM_SLEEP_ON_AC=deep
STOP
    }

    __cpu() {
        # REF:
        #   https://unix.stackexchange.com/questions/439340/what-are-the-implications-of-setting-the-cpu-governor-to-performance
        #   https://github.com/erpalma/throttled?tab=readme-ov-file#hwp-override-experimental

        sudo tee "${_dir}/cpu.conf" <<STOP >/dev/null
# CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_AC=powersave
# CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_MIN_PERF_ON_AC=10
CPU_MAX_PERF_ON_AC=100

CPU_SCALING_GOVERNOR_ON_BAT=powersave
# CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
CPU_ENERGY_PERF_POLICY_ON_BAT=power
CPU_MIN_PERF_ON_BAT=10
CPU_MAX_PERF_ON_BAT=67
STOP
    }

    __gpu() {
        # REF:
        #   https://linrunner.de/tlp/settings/graphics.html
        sudo tee "${_dir}/gpu.conf" <<STOP >/dev/null
INTEL_GPU_MIN_FREQ_ON_BAT=300
INTEL_GPU_MAX_FREQ_ON_BAT=790
INTEL_GPU_BOOST_FREQ_ON_BAT=970
STOP
    }

    __radio() {
        sudo tee "${_dir}/radio.conf" <<STOP >/dev/null
DEVICES_TO_DISABLE_ON_LAN_CONNECT="wifi wwan"
DEVICES_TO_DISABLE_ON_WIFI_CONNECT="wwan"
DEVICES_TO_DISABLE_ON_WWAN_CONNECT="wifi"

DEVICES_TO_ENABLE_ON_LAN_DISCONNECT=""
DEVICES_TO_ENABLE_ON_WIFI_DISCONNECT=""
DEVICES_TO_ENABLE_ON_WWAN_DISCONNECT=""
STOP
    }

    __usb() {
        # NOTE:
        #   0 := allow autosuspending
        #   1 := disallow autosuspending, i.e., keep alive
        sudo tee "${_dir}/usb.conf" <<STOP >/dev/null
USB_EXCLUDE_AUDIO=0
USB_EXCLUDE_BTUSB=0
USB_EXCLUDE_PRINTER=0
USB_EXCLUDE_WWAN=0

USB_EXCLUDE_PHONE=1
STOP
    }

    __platform
    __cpu
    __gpu
    __radio
    __usb

    sudo tlp start
    # sudo tlp-stat --config
    sudo tlp-stat --cdiff
}

__sleep
__thinkfan
__tlp
