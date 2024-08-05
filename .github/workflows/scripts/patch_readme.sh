#!/bin/bash

README_FILE=$(dirname "$0")/../../../README.md
TMP_FILE=/tmp/README_TABLE.md

# Generate new MD table:
$(dirname "$0")/get_openwrt_latest_versions.sh >$TMP_FILE

# Cut old MD table:
sed -i "/<!--versions-table-start-->/,/<!--versions-table-end-->/{//!d;}" "$README_FILE"

# Insert new MD table before end tag:
sed -e "N;/\n.*<!--versions-table-end-->/{r $TMP_FILE" -e "};P;D" -i "$README_FILE"

cat $TMP_FILE
