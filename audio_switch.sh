#!/bin/bash

PREFERRED_HEADSET_SINKS=(
    "alsa_output.usb-Corsair_CORSAIR_HS80_RGB_Wireless_Gaming_Receiver_16ad2621000300da-00.analog-stereo"
)

PREFERRED_SPEAKER_SINKS=(
    "alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio__sink"
)

list_sinks() {
    pactl list short sinks 2>/dev/null | awk '{print $2}'
}

pick_sink_by_name() {
    local candidate

    for candidate in "$@"; do
        list_sinks | grep -Fxm1 "$candidate" && return 0
    done
    return 1
}

pick_sink_by_pattern() {
    local pattern="$1"

    list_sinks | grep -Eim1 "$pattern"
}

get_headset_sink() {
    pick_sink_by_name "${PREFERRED_HEADSET_SINKS[@]}"
}

get_speaker_sink() {
    local headset_sink

    headset_sink="$(get_headset_sink)"
    pick_sink_by_name "${PREFERRED_SPEAKER_SINKS[@]}" | grep -Fvx "$headset_sink"
}

get_fallback_sink() {
    local exclude="$1"

    list_sinks | grep -Fvx "$exclude" | head -n1
}

move_inputs() {
    local target="$1"

    pactl list short sink-inputs 2>/dev/null | awk '{print $1}' | while read -r input_id; do
        [ -n "$input_id" ] && pactl move-sink-input "$input_id" "$target" >/dev/null 2>&1
    done
}

set_target_sink() {
    local target="$1"

    [ -z "$target" ] && exit 1
    pactl set-default-sink "$target" >/dev/null 2>&1 || exit 1
    move_inputs "$target"
}

case "$1" in
    status)
        current="$(pactl get-default-sink 2>/dev/null)"
        headset_sink="$(get_headset_sink)"
        speaker_sink="$(get_speaker_sink)"

        if [ -z "$current" ]; then
            echo "%{F#ff5555}AUD%{F-}"
        elif [ -n "$headset_sink" ] && [ "$current" = "$headset_sink" ]; then
            echo "%{F#00f3ff}HPH%{F-}"
        elif [ -n "$speaker_sink" ] && [ "$current" = "$speaker_sink" ]; then
            echo "%{F#39ff14}SPK%{F-}"
        else
            echo "%{F#ffd166}AUD%{F-}"
        fi
        ;;
    toggle)
        current="$(pactl get-default-sink 2>/dev/null)"
        headset_sink="$(get_headset_sink)"
        speaker_sink="$(get_speaker_sink)"

        if [ -z "$headset_sink" ] && [ -z "$speaker_sink" ]; then
            exit 1
        fi

        if [ -n "$headset_sink" ] && [ "$current" = "$headset_sink" ]; then
            target="${speaker_sink:-$(get_fallback_sink "$headset_sink")}"
        else
            target="${headset_sink:-${speaker_sink:-$(get_fallback_sink "$current")}}"
        fi

        set_target_sink "$target"
        ;;
esac
