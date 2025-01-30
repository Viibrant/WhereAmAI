#!/bin/bash

# Ensure we're in the project root
cd "$(dirname "$0")"

# Load environment variables from .env file if exists
if [ -f .env ]; then
    export $(grep -v "^#" .env | xargs)
else
    echo "[ERROR] No .env file found! Create one with B2 credentials."
    exit 1
fi

# Ensure B2_BUCKET_NAME is set
if [ -z "$B2_BUCKET_NAME" ]; then
    echo "[ERROR] B2_BUCKET_NAME is not set in the .env file!"
    exit 1
fi

# Ensure `rclone` remote is set up
if ! rclone listremotes | grep -q "whereamai-b2:"; then
    echo "[INFO] Configuring rclone remote..."
    rclone config create whereamai-b2 b2 account "$B2_ACCOUNT_ID" key "$B2_APP_KEY"
fi

# Ensure mount directory exists
mkdir -p data/datasets

# Check if already mounted
if mount | grep -q "$(realpath data/datasets)"; then
    echo "[INFO] B2 is already mounted at data/datasets."
    exit 0
fi

# Kill any stuck mounts
pkill -f "rclone mount whereamai-b2" 2>/dev/null

# Mount B2 storage in background (WITHOUT `--allow-other`)
echo "[INFO] Mounting B2 storage at data/datasets..."
nohup rclone mount whereamai-b2:"$B2_BUCKET_NAME" data/datasets --vfs-cache-mode writes > rclone.log 2>&1 &

# Wait a second to ensure mount is running
sleep 2

# Verify mount success
if mount | grep -q "$(realpath data/datasets)"; then
    echo "[SUCCESS] B2 is now mounted at data/datasets"
else
    echo "[ERROR] Mount failed. Check logs in rclone.log"
fi
