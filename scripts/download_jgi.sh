#!/bin/bash
#

# Usage: bash download_jgi /path/to/download/directory
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
ROOT_DIR="${DOWNLOAD_DIR}/JGIclust"

SOURCE_URL="https://zhanggroup.org/ftp/data/JGIclust30"

# Download list file.
mkdir -p ${ROOT_DIR}
#aria2c -c --dir="${ROOT_DIR}" ${SOURCE_URL}/list
#
## Download db file one by one.
#for db in $(cat ${ROOT_DIR}/list); do
#  echo "Downloading JGI db ${db}"
#  aria2c -c --dir="${ROOT_DIR}" ${SOURCE_URL}/${db}.xz
#  aria2c -c --dir="${ROOT_DIR}" ${SOURCE_URL}/${db}.ssi.xz
#done

# Decompress each db file
for db in $(cat ${ROOT_DIR}/list); do
  pushd "${ROOT_DIR}"
  echo "Decompressing JGI db ${db}"
  xz -dvf ${db}.xz
  xz -dvf ${db}.ssi.xz
  popd
done
