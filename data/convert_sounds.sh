#!/bin/bash

mkdir -p ../sounds

# Loop through each instrument folder
for dir in ./instruments/*/; do
    [ -d "${dir}sounds" ] || continue

    instrument="$(basename "$dir")"

    # Loop through all files in sounds/
    for file in "${dir}sounds"/*; do
        [ -f "$file" ] || continue

        filename="$(basename "${file%.*}")"

        ffmpeg -y -i "$file" "../sounds/${instrument}_${filename}.ogg"
    done
done