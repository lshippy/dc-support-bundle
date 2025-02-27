#!/bin/bash

echo "Starting FileBrowser..."

docker run --rm -d \
    --name filebrowser \
    -p 8080:80 \
    --tmpfs /srv:size=100m \
    -e FB_NOAUTH=true \
    filebrowser/filebrowser

echo "⏳ Waiting for FileBrowser to start..."
sleep 5

if ! docker ps --format '{{.Names}}' | grep -q "^filebrowser$"; then
    echo "Error: FileBrowser container failed to start!"
    exit 1
fi

echo "FileBrowser is running at: http://localhost:8080"
echo "Watching for ZIP files to extract..."

while true; do
    zip_files=$(docker exec filebrowser sh -c 'find /srv -maxdepth 1 -type f -name "*.zip" 2>/dev/null')

    if [ -z "$zip_files" ]; then
        sleep 3
        continue
    fi

    while IFS= read -r zip_file; do
        if [ -n "$zip_file" ]; then
            echo "Extracting \"$zip_file\"..."

            docker exec filebrowser sh -c "unzip -o \"$zip_file\" -d \"/srv\""

            if [ $? -eq 0 ]; then
                echo "Deleting \"$zip_file\"..."
                docker exec filebrowser sh -c "rm \"$zip_file\""

                echo "Refresh your FileBrowser window to see the extracted files."
            else
                echo "Extraction failed for \"$zip_file\""
            fi
        fi
    done <<< "$zip_files"

    sleep 3
done