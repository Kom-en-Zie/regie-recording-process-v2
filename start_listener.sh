#!/bin/bash

# Get the directory of the current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source "$SCRIPT_DIR/variables.sh"

echo "Starting listener on folder: $RECORD_DIR"

# --- Watch Loop ---
# -m: monitor mode, keeps running forever
# -e close_write: event that triggers when a file is finished being written
# --format '%w%f': outputs the full path of the file
inotifywait -m -e close_write --format '%w%f' "$RECORD_DIR" | while read -r FILE
do
    # Ensure we only process .mkv files
    if [[ "$FILE" == *.mkv ]]; then
        echo "----------------------------------------------------"
        echo "Listener detected new file: $FILE"
        echo "Calling processing script..."
        # Call the main script and pass the file path to it
        bash "$PROCESS_SCRIPT" "$FILE"
    fi
done
