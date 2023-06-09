#!/bin/bash
set -e;

# Directory where the prepare.sh script is placed.
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)";
[ "$(pwd)/steps" != "$SDIR" ] && \
    echo "Please, run this script from the experiment top directory!" >&2 && \
    exit 1;
[ ! -f "$(pwd)/utils/parse_options.inc.sh" ] &&
echo "Missing $(pwd)/utils/parse_options.inc.sh file!" >&2 && exit 1;

iam_pass=;
iam_user=;
partition=lines;
help_message="
Usage: ${0##*/} [options]

Options:
  --iam_pass   : (type = string, default = \"$iam_pass\")
                 Password for the IAM server.
  --iam_user   : (type = string, default = \"$iam_user\")
                 Username for the IAM server.
  --partition  : (type = string, default = \"$partition\")
                 Select the \"lines\" or \"sentences\" partition. Note: Aachen
                 typically uses the sentences partition.
";
source "$(pwd)/utils/parse_options.inc.sh" || exit 1;

# Utility function to download files from IAM. --user="$iam_user" --password="$iam_pass"
function download_url () {
  [ -z "$iam_user" -o -z "$iam_pass" ] && \
    echo "Please, use the --iam_user and --iam_pass options to download" \
	 "the database from the IAM servers." >&2 && return 1;
  wget -P data/original --load-cookies /home/jesse/Laia/egs/iam/steps/cookies.txt "$1" ||
  { echo "ERROR: Failed downloading $1!" >&2 && return 1; }
  return 0;
}


tmpd="$(mktemp -d)";


case "$partition" in
  "lines")
    mkdir -p data/original/lines;
    url="https://fki.tic.heia-fr.ch/DBs/iamDB/data/lines.tgz";
    # Download lines images from IAM.
    [ -s data/original/lines.tgz ] || download_url "$url" || exit 1;
    # Untar and put all lines images into a single directory.
    [ -s data/original/lines/a01-000u-00.png -a \
      -s data/original/lines/r06-143-04.png ] || (
      tar zxf data/original/lines.tgz -C "$tmpd" &&
      find "$tmpd" -name "*.png" | xargs -I{} mv {} data/original/lines; ) ||
      ( echo "ERROR: Failed extracting IAM line image files." >&2 && exit 1 );
    ;;
  "sentences")
    mkdir -p data/original/sentences;
    url="https://fki.tic.heia-fr.ch/DBs/iamDB/data/sentences.tgz";
    # Download sentences images from IAM.
    [ -s data/original/sentences.tgz ] || download_url "$url" || exit 1;
    # Untar and put all sentence images into a single directory.
    [ -s data/original/sentences/a01-000u-s00-00.png -a \
      -s data/original/sentences/r06-143-s04-01.png ] || (
      tar zxf data/original/sentences.tgz -C "$tmpd" &&
      find "$tmpd" -name "*.png" | xargs -I{} mv {} data/original/sentences;) ||
    ( echo "ERROR: Failed extracting IAM sentence image files." >&2 && exit 1 );
    ;;
  *)
    echo "ERROR: Unknown partition \"$partition\"!" >&2 && exit 1;
esac;

# Download ascii files.
url="https://fki.tic.heia-fr.ch/DBs/iamDB/data/ascii.tgz";
[ -s data/original/ascii.tgz ] || download_url "$url" || exit 1;

# Untar ascii files.
[ -s data/original/lines.txt -a -s data/original/sentences.txt \
  -a -s data/original/forms.txt -a -s data/original/words.txt ] ||
tar zxf data/original/ascii.tgz -C data/original ||
( echo "ERROR: Failed extracting IAM ascii files." >&2 && exit 1 );

rm -rf "$tmpd";
exit 0;
