#!/bin/bash
SPEAKERS="alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio__sink"
HEADSET="alsa_output.usb-Corsair_CORSAIR_HS80_RGB_Wireless_Gaming_Receiver_16ad2621000300da-00.analog-stereo"

case "$1" in
    status)
        CURRENT=$(pactl get-default-sink 2>/dev/null)
        if [ "$CURRENT" = "$HEADSET" ]; then
            echo "%{F#00f3ff}HPH%{F-}"
        else
            echo "%{F#39ff14}SPK%{F-}"
        fi
        ;;
    toggle)
        CURRENT=$(pactl get-default-sink 2>/dev/null)
        if [ "$CURRENT" = "$HEADSET" ]; then
            pactl set-default-sink "$SPEAKERS" 2>/dev/null
        else
            pactl set-default-sink "$HEADSET" 2>/dev/null
        fi
        ;;
esac
