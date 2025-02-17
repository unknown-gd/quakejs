#!/bin/bash

# Sean Begley
# 2017-07-06 (Updated)

# Unknown Developer
# 2025-02-17 (Fixed)

# Bash Script to download all Assets from a quakejs content server.
# The default server is http://content.quakejs.com

# OPTIONAL first parameters ($1) = address of alternate quakejs content server

# EXAMPLE USAGE
# ./get_assets.sh
# ./get_assets.sh /alternate/output/folder
# ./get_assets.sh /alternate/output/folder http://alternate.content.server.com

# Setup output folder (default: ".")
output_dir="."
if [ ! -z "$1" ]; then
    output_dir="$1"
fi

# Setup content server address (default: http://content.quakejs.com)
server="http://content.quakejs.com"
if [ ! -z "$2" ]; then
    server="$2"
fi

printf "Using content server: %s\n" "$server"

# Download manifest.json and get the number of assets available
printf "Downloading manifest.json\n"
mkdir -p "$output_dir/assets"

wget --quiet --continue --no-clobber -O "$output_dir/assets/manifest.json" "$server/assets/manifest.json"

# Ensure jq exists
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is required but not installed. Install it and try again."
    exit 1
fi

num_elems=$(jq '. | length' "$output_dir/assets/manifest.json")

printf "%d assets found in manifest.json\n" "$num_elems"

# Loop through manifest and download each file
for i in $(seq 0 $((num_elems - 1))); do
    name=$(jq -r ".[$i].name" "$output_dir/assets/manifest.json")
    checksum=$(jq -r ".[$i].checksum" "$output_dir/assets/manifest.json")

    # Split name into tokens
    IFS='/' read -ra name_tokens <<< "$name"

    if [ "${#name_tokens[@]}" -eq 1 ]; then
        filename="${name_tokens[0]}"
        download_path="assets"
    else
        filename="${name_tokens[1]}"
        download_path="assets/${name_tokens[0]}"
    fi

    printf "Downloading %s to %s/%s\n" "$name" "$output_dir" "$download_path/$filename"

    # Create directory if it doesn't exist
    mkdir -p "$output_dir/$download_path"

    # Download file
    wget --quiet --continue --no-clobber -O "$output_dir/$download_path/$filename" "$server/$download_path/$checksum-$filename"
done

printf "Download complete.\n"
