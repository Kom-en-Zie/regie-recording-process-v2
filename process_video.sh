#!/bin/bash

source ./variables.sh

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The full path to the new MKV file passed from the listener
SOURCE_MKV="$1"

# --- Logging ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# --- Main Logic ---
log "----------------------------------------------------"
log "Starting new workflow for: $SOURCE_MKV"

# Get the base filename without the extension
BASENAME=$(basename "$SOURCE_MKV" .mkv)

# Define target file paths
MP4_TARGET="$CONVERT_DIR/$BASENAME.mp4"
MOV_TARGET="$CONVERT_DIR/$BASENAME.mov"

# 1. CONVERSION (FFmpeg)
# This happens locally in the 'Conversion folder' for max speed.

log "Starting MP4 (H.264) conversion..."
# -i: input file
# -c:v libx264: H.264 video codec
# -preset slow: Good balance of quality and encoding time
# -crf 22: Constant Rate Factor for quality (lower is better, 18-28 is a good range)
# -c:a copy: Copies the audio stream without re-encoding, which is faster.
ffmpeg -i "$SOURCE_MKV" -c:v libx264 -preset slow -crf 22 -c:a copy "$MP4_TARGET" -y
log "MP4 conversion finished."

log "Starting MOV (H.265) conversion..."
# -c:v libx265: H.265 (HEVC) video codec for higher efficiency
# -crf 24: A CRF of 24 for x265 is visually comparable to ~22 for x264
# -tag:v hvc1: Adds a tag for better compatibility with Apple devices
ffmpeg -i "$SOURCE_MKV" -c:v libx265 -preset slow -crf 24 -c:a copy -tag:v hvc1 "$MOV_TARGET" -y
log "MOV conversion finished."

# 2. UPLOAD (Move to NAS) & VERIFY

# Move the new files to the NAS
log "Moving converted files to NAS..."
mv "$MP4_TARGET" "$NAS_DIR/"
mv "$MOV_TARGET" "$NAS_DIR/"

# Verify by comparing checksums to ensure the move was successful
log "Verifying file integrity on NAS..."
MP4_ON_NAS="$NAS_DIR/$BASENAME.mp4"
MOV_ON_NAS="$NAS_DIR/$BASENAME.mov"

if [ -f "$MP4_ON_NAS" ] && [ -f "$MOV_ON_NAS" ]; then
    log "Verification successful. Files are on the NAS."

    # 3. CLEANUP
    log "Deleting original MKV file: $SOURCE_MKV"
    rm "$SOURCE_MKV"
    log "Workflow complete for $BASENAME."
else
    log "ERROR: Verification failed! One or both files are missing from the NAS."
    exit 1
fi
