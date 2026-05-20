#!/bin/bash

WORKDIR="${AI_WORKDIR:-/home/lu47/Desktop/Lucholabs}"

case "$1" in
    codex)
        CMD="codex"
        TITLE="GPT"
        ;;
    claude)
        CMD="claude"
        TITLE="Claude"
        ;;
    gemini)
        CMD="gemini"
        TITLE="Gemini"
        ;;
    *)
        exit 1
        ;;
esac

exec /usr/bin/kitty --directory "$WORKDIR" --title "$TITLE" bash -ilc "exec $CMD"
