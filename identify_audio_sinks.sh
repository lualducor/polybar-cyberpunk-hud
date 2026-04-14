#!/bin/bash

set -u

SINK_NAMES=(
    "alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio_2__sink"
    "alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio_1__sink"
    "alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio__sink"
    "alsa_output.usb-Corsair_CORSAIR_HS80_RGB_Wireless_Gaming_Receiver_16ad2621000300da-00.analog-stereo"
    "alsa_output.pci-0000_01_00.1.hdmi-stereo"
)

declare -A SINK_DESCRIPTIONS=(
    ["alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio_2__sink"]="USB Audio S/PDIF Output"
    ["alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio_1__sink"]="USB Audio Front Headphones"
    ["alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio__sink"]="USB Audio Speakers"
    ["alsa_output.usb-Corsair_CORSAIR_HS80_RGB_Wireless_Gaming_Receiver_16ad2621000300da-00.analog-stereo"]="CORSAIR HS80 RGB Wireless Gaming Receiver Analog Stereo"
    ["alsa_output.pci-0000_01_00.1.hdmi-stereo"]="GA102 High Definition Audio Controller Digital Stereo (HDMI)"
)

HEADSET_MATCHES=()
SPEAKER_MATCHES=()

original_sink="$(pactl get-default-sink 2>/dev/null)"

restore_default_sink() {
    [ -n "${original_sink:-}" ] && pactl set-default-sink "$original_sink" >/dev/null 2>&1
}

play_tone() {
    local sink="$1"

    pactl set-default-sink "$sink" >/dev/null 2>&1 || return 1
    printf "\nTesting: %s\n" "$sink"
    printf "Description: %s\n" "${SINK_DESCRIPTIONS[$sink]}"
    printf "Playing test tone for 3 seconds...\n"
    timeout 3s speaker-test -D default -t sine -f 660 -c 2 >/dev/null 2>&1
}

prompt_label() {
    local sink="$1"

    while true; do
        printf "\nLabel this sink: [h]eadset, [s]peakers, [o]ther, [r]eplay, [q]uit: "
        read -r answer

        case "$answer" in
            h|H)
                HEADSET_MATCHES+=("$sink")
                return 0
                ;;
            s|S)
                SPEAKER_MATCHES+=("$sink")
                return 0
                ;;
            o|O|"")
                return 0
                ;;
            r|R)
                play_tone "$sink" || return 1
                ;;
            q|Q)
                return 2
                ;;
            *)
                printf "Invalid choice.\n"
                ;;
        esac
    done
}

trap restore_default_sink EXIT

printf "Audio sink identification\n"
printf "Current default sink: %s\n" "${original_sink:-unknown}"
printf "You will hear a short tone on each sink.\n"

for sink in "${SINK_NAMES[@]}"; do
    pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -Fxq "$sink" || continue

    play_tone "$sink" || {
        printf "Failed to test %s\n" "$sink"
        continue
    }

    prompt_label "$sink"
    status=$?
    if [ "$status" -eq 2 ]; then
        break
    fi
done

printf "\nSummary\n"
printf "Headset sinks:\n"
for sink in "${HEADSET_MATCHES[@]}"; do
    printf "  \"%s\"\n" "$sink"
done

printf "Speaker sinks:\n"
for sink in "${SPEAKER_MATCHES[@]}"; do
    printf "  \"%s\"\n" "$sink"
done

printf "\nHardcode these into ~/.config/polybar/audio_switch.sh\n"
