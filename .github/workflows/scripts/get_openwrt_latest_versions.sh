#!/bin/bash

[[ -z "$REPO" ]] && REPO="b0rder/openwrt-a5-v11"

cat <<_EOF
| OpenWRT version | OpenWRT release date | A5-V11 OpenWRT Release mod |
| --------------- | -------------------- | -------------------------- |
_EOF

curl -sL https://api.github.com/repos/openwrt/openwrt/git/matching-refs/tags/v \
| jq -r '.[] | select(.ref | test("v(\\d+\\.?){3}$")?) | "\(.ref) \(.object.url)"' | tac | awk -F. '!seen[$1]++' \
| while read -r n
do
  REF=${n% *}
  V=${REF#refs/tags/}
  URL=${n#* }
  D=$(curl -sL "$URL" | jq -r .tagger.date)
  echo -n "| [$V](https://github.com/openwrt/openwrt/tree/$V) | "
  if [[ $(curl -sI --write-out "%{http_code}" -o /dev/null https://api.github.com/repos/openwrt/openwrt/releases/tags/$V) -eq 200 ]] ; then
    echo -n "[$D](https://github.com/$REPO/releases/tag/$V)"
  else 
    echo -n "$D"
  fi
  echo -n " | "
  if [[ $(curl -H "Authorization: Bearer $TOKEN" -sI --write-out "%{http_code}" -o /dev/null https://api.github.com/repos/$REPO/releases/tags/$V) -eq 200 ]] ; then
    echo -n "**[$V](https://github.com/$REPO/releases/tag/$V)**"
  else 
    echo -n "$V"
  fi
  echo " |"
done
