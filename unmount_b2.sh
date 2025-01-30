#!/bin/bash

# Ensure we're in the project root
cd "$(dirname "$0")"

# Unmount the storage
echo "[INFO] Unmounting B2 storage..."
fusermount -u data/datasets || umount data/datasets

# Kill any lingering rclone processes
pkill -f "rclone mount whereamai-b2"

# Verify unmount success
if mount | grep -q "$(realpath data/datasets)"; then
    echo "[ERROR] Unmount failed!"
else
    echo "[SUCCESS] B2 storage unmounted."
fi
