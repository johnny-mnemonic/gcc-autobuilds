#!/bin/bash

# build order

for _job in @@_BUILD_ORDER_@@; do

	pushd /usr/src/t2-src &>/dev/null

	date

	time scripts/Build-Target -cfg @@_TARGET_CONFIG_@@ -job $_job || touch /BUILD_FAILED

	date

	popd &>/dev/null
done

exit
