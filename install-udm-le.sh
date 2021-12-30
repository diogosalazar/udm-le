#!/bin/sh
# This script downloads the latest udm-le and installs it
# to the data directory (/mnt/data or /data, whichever exists).
set -e

# Defines
REPO_URL="diogosalazar/udm-le"

# Get the persistent data directory
if [ -d "/mnt/data" ]; then
	DATA_DIR="/mnt/data"
elif [ -d "/data" ]; then
	DATA_DIR="/data"
else
	echo ERROR: Could not find the data directory.
	exit 1
fi

# Download and install
mkdir -p "${DATA_DIR}/udm-le"
cd "${DATA_DIR}/udm-le"
echo Downloading latest udm-le...
curl -LsSfo udm-le.zip https://github.com/${REPO_URL}/archive/main.zip
echo Installing to "${DATA_DIR}/udm-le"...
unzip -oq udm-le.zip
cp -rf udm-le-main/udm-le ./
rm -rf udm-le-main udm-le.zip

# Link to /etc
rm -f /etc/udm-le
ln -sf "${DATA_DIR}/udm-le" /etc/udm-le 

echo udm-le has been installed to "${DATA_DIR}/udm-le" and linked to /etc/udm-le.
echo Please configure \"/etc/udm-le/udm-le.env\" with your provider settings and run \"udm-le initial\"