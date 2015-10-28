#!/bin/bash
# Pre-build all possible platforms
PLATFORMS=`grep -Pow "PLATFORM_ID\s?=\s?(\d+)$" /firmware/build/platform-id.mk`
cd /firmware/main
while read -r PLATFORM; do
	PLATFORM="$(tr -d " " <<<$PLATFORM)"
	eval "$PLATFORM make"
done <<< "$PLATFORMS"
