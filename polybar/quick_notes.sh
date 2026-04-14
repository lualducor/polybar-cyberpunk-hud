#!/bin/bash
NOTES_FILE="$HOME/notes.txt"
touch "$NOTES_FILE"
xterm -geometry 100x25+560+200 \
    -title "// QUICK NOTES //" \
    -bg "#0d1117" \
    -fg "#a9fef7" \
    -fa "JetBrainsMono" \
    -fs 11 \
    -e "nano $NOTES_FILE" &
