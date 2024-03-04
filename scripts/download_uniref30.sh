#!/bin/bash
#

# Usage: bash download_uniref30.sh /path/to/download/directory
set -e

if [[ $# -eq 0 ]]; then
  echo "Error: download directory must be provided as an input argument."
  exit 1
fi

if ! command -v aria2c &> /dev/null ; then
  echo "Error: aria2c could not be found. Please install aria2c (sudo apt install aria2)."
  exit 1
fi


DOWNLOAD_DIR="$1"
ROOT_DIR="${DOWNLOAD_DIR}/uniref30"

SOURCE_URL="https://zhanggroup.org/ftp/data/UniRef30_2022_02.zip"

# Download db.
mkdir -p ${ROOT_DIR}
aria2c -c --dir="${ROOT_DIR}" ${SOURCE_URL}

# Decompress each db file
pushd "${ROOT_DIR}"
unzip -u UniRef30_2022_02.zip
popd

