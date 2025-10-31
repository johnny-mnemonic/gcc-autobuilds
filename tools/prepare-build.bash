#!/bin/bash

# prepare build

_config_dir="$CONFIG_DIR"
_tools_dir="$TOOLS_DIR"
_env_dest="$T2_ROOT"

# determine build order
if [[ -e "build_gcc" ]]; then

	_build="gcc"
else
	# exit early
	echo "I: No build needed." 1>&2
	exit 0
fi

# create build commands ("built order") according to configured build order
case ${_build} in

	gcc)
		_build_order="0-gcc 1-gcc 2-gcc"
		;;
esac

sed -e "s/@@_BUILD_ORDER_@@/${_build_order}/" \
    -e "s/@@_TARGET_CONFIG_@@/$( cat target_config )/" \
    "${_config_dir}/build-order.tpl" > "${_env_dest}/build-order.bash" || exit 1

# place main build script in build environment
cp "${_tools_dir}/perform-build.bash" "${_env_dest}/" || exit 1

# make sure the scripts are executable
chmod +x ${_env_dest}/{perform-build.bash,build-order.bash} || exit 1

# also echo build order for other tools to be able to use it
echo "${_build_order}"

exit
