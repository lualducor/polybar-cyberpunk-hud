#!/bin/bash
NOTES_FILE="$HOME/notes.txt"
touch "$NOTES_FILE"
subl "$NOTES_FILE" &
