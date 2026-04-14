#!/bin/bash

if ! command -v playerctl >/dev/null 2>&1; then
    exit 1
fi

find_player() {
    playerctl -l 2>/dev/null | grep -Ei 'spotify|spotifyd' | head -n1
}

player="$(find_player)"
[ -z "$player" ] && exit 1

if [ "$1" = "--print-player" ]; then
    echo "$player"
    exit 0
fi

playerctl --player="$player" "$@"
