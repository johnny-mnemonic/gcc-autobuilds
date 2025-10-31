#!/bin/bash

# prepare snapshot file for T2 build

_t2_template_base_dir="$T2_TEMPLATE_BASE_DIR"

_snapshot_url="$1"
_snapshot_file="$2"

_config_dir="$CONFIG_DIR"

if [[ "$1" == "" ]]; then

	echo "usage: $( basename $0 ) <SNAPSHOT_URL> <SNAPSHOT_FILE>" 1>&2
	exit 64
fi

# determine GCC version for template file
_version=$( echo ${_snapshot_url} | sed -e 's|^.*/LATEST-.*/gcc-||' -e 's|.tar.*$||' )

_remote_dir=$( dirname "$_snapshot_url" )

_snapshot_filename=$( basename "$_snapshot_file" )

_package=${_snapshot_filename%%-*}

_suffix=${_snapshot_filename//*.tar.}

case ${_suffix} in

	xz)
		_decompressor="xzcat"
		;;

	zst)
		_decompressor="zstdcat"
		;;

	gz)
		_decompressor="zcat"
		;;

	*)
		echo "E: unknown suffix \`$_suffix'. Cannot continue." 1>&2
		exit 2
esac

# get SHA224 hash for T2 <PACKAGE>.desc file
_sha224_hash=$( ${_decompressor} ${_snapshot_file} | sha224sum | cut -d ' ' -f 1 )

case ${_package} in

	binutils | gcc)
		_t2_template_package_base_dir="${_t2_template_base_dir}/package/develop"
		;;

	glibc)
		_t2_template_package_base_dir="${_t2_template_base_dir}/package/base"
		;;

	*)
		echo "E: unknown package \`$_package'. Cannot continue." 1>&2
		exit 3
		;;
esac

# equip .desc file template

# @@_VERSION_@@ @@_HASH_@@ @@_SNAPSHOT_FILENAME_@@ @@_REMOTE_DIR_@@

sed -e "s|@@_HASH_@@|${_sha224_hash}|" \
    -e "s|@@_SNAPSHOT_FILENAME_@@|${_snapshot_filename}|" \
    -e "s|@@_REMOTE_DIR_@@|${_remote_dir}/|" \
    -e "s|@@_VERSION_@@|${_version}|" \
    "${_t2_template_package_base_dir}/${_package}/${_package}.desc.tpl" > \
    "${_t2_template_package_base_dir}/${_package}/${_package}.desc"

exit
