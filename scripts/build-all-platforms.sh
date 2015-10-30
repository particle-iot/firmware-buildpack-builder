#!/bin/bash
# Pre-build all possible platforms
PLATFORMS=`grep -Pow "PLATFORM_ID\s?=\s?(\d+)$" /firmware/build/platform-id.mk`
while read -r PLATFORM; do
	PLATFORM="$(tr -d " " <<<$PLATFORM)"
	cd /firmware/main
	eval "$PLATFORM make"
	cd /firmware/modules
	eval "$PLATFORM make"
done <<< "$PLATFORMS"
# Return with code 0 to ignore "Platform X does not support dynamic modules" error
exit 0
