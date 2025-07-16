#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source "$SCRIPT_DIR/variables.sh"
source "$SCRIPT_DIR/functions.sh"

transcribeMkv() {
  # $1: the video file to transcribe
  local BASENAME
  BASENAME=$(basename "$1" .mkv)
  ffmpeg -i "$1" -vn -map_metadata -1 -ac 1 -c:a libopus -b:a 12k -application voip "$CONVERT_DIR/$BASENAME.ogg"
  if [ $? -ne 0 ]; then
    log "Error: ffmpeg failed to convert '$1' to OGG."
    return 1 # Indicate an error
  fi

  whisper "$CONVERT_DIR/$BASENAME.ogg" --model turbo --language nl --output_format txt --output_dir . > "$CONVERT_DIR/$BASENAME.txt"
  local WHISPER_EXIT_CODE=$?
  if [ "$WHISPER_EXIT_CODE" -ne 0 ]; then
    log "An error happened while executing: whisper \"$CONVERT_DIR/$BASENAME.ogg\" --model turbo --language nl --output_format txt --output_dir . > \"$CONVERT_DIR/$BASENAME.txt\""
    log "- error: Exit code $WHISPER_EXIT_CODE"
    # Optionally, you might want to return an error status from the function
    return 1
  fi

  rm "$CONVERT_DIR/$BASENAME.ogg"
}
