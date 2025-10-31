#!/bin/bash

# set up build environment

# builds one target environment only!

_config_dir="$CONFIG_DIR"
_snapshots_dir="$SNAPSHOTS"
_t2_template_base_dir="$T2_TEMPLATE_BASE_DIR"

. ${_config_dir}/build.env

error()
{
	local _exit_code="$1"
	local _message="$2"

	echo -e "${_message}" 1>&2
	exit $_exit_code
}

# make build environment
case ${_env_mode} in

	download)
		# download env tarball and check integrity
		_env_tarball="$PWD/$( basename ${_env_url} )"
		echo -n "I: downloading \`${_env_url}'... " 1>&2
		_actual_hash=$( wget "$_env_url" -O - 2>/dev/null | tee "$_env_tarball" | sha512sum | cut -d ' ' -f1 )

		if [[ "$_env_hash" != "$_actual_hash" ]]; then

			error 2 "\nE: downloaded environment does not match configured hash value. Will not continue."
		else
			echo "OK" 1>&2
		fi

		echo -n "I: untarring \`${_env_tarball}'... " 1>&2
		tar --numeric-owner -xf "$_env_tarball" || error 3 "\nE: problem during untarring build environment. Will not continue."
		echo "OK" 1>&2

		rm -f "$_env_tarball"
		;;

	build)
		# build env
		# get/mount ISO for local arch (x86_64)
		# unpack (all?) tarballs
		# run post install scripts where it makes sense
		# define nameserver in `/etc/resolv.conf`
		error 1 "E: not implemented."
		;;
esac

# configure `/etc/resolv.conf` for build env if needed
if [[ $_env_configure_dns -eq 1 ]]; then

	cat "${_config_dir}/resolv.conf" > "${_env_dest}/etc/resolv.conf"
fi

# get T2 sources
case ${_t2_sources_mode} in

	official)
		pushd "${_env_dest}/usr/src" &>/dev/null
		echo -n "I: checking out official T2 sources from \`${_t2_official_sources_url}'... " 1>&2
		svn co --force "$_t2_official_sources_url" "t2-src" || error 4 "\nE: problem when checking out the official T2 sources. Cannot continue."
		echo "OK" 1>&2
		popd &>/dev/null
		;;

	specific)
		_sources_tarball="$PWD/$( basename ${_t2_sources_url} )"
		echo -n "I: downloading specific sources from \`${_t2_sources_url}'... " 1>&2
		_actual_hash=$( wget "$_t2_sources_url" -O - 2>/dev/null | tee "$_sources_tarball" | sha512sum | cut -d ' ' -f1 )

		if [[ "$_t2_sources_hash" != "$_actual_hash" ]]; then

			error 2 "\nE: downloaded environment does not match configured hash value. Will not continue."
		else
			echo "OK" 1>&2
		fi

		pushd "${_env_dest}/usr/src" &>/dev/null
		echo -n "I: untarring \`${_sources_tarball}'... " 1>&2
		tar --numeric-owner -xf "$_sources_tarball" || error 3 "\nE: problem during untarring T2 sources. Will not continue."
		echo "OK" 1>&2
		popd &>/dev/null

		rm -f "$_sources_tarball"
		;;
esac

# make target environment
case ${_t2_target_env_mode} in

	build)
		error 1 "E: not implemented."
		;;

	download)
		_target_env_tarball="$PWD/$( basename ${_env_url} )"
		echo -n "I: downloading target environment from \`${_t2_target_env_url}'... " 1>&2
		_actual_hash=$( wget "$_t2_target_env_url" -O - 2>/dev/null | tee "$_target_env_tarball" | sha512sum | cut -d ' ' -f1 )

		if [[ "$_t2_target_env_hash" != "$_actual_hash" ]]; then

			error 2 "\nE: downloaded target environment does not match configured hash value. Will not continue."
		else
			echo "OK" 1>&2
		fi

		pushd "${_env_dest}/usr/src/t2-src" &>/dev/null
		echo -n "I: untarring \`${_target_env_tarball}'... " 1>&2
		tar --numeric-owner -xf "$_target_env_tarball" || error 3 "\nE: problem during untarring target environment. Will not continue."
		echo "OK" 1>&2
		popd &>/dev/null

		rm -f "$_target_env_tarball"
		;;
esac

# place downloads and prepared template dirs for packages
echo -n "I: placing downloads and prepared template directories... " 1>&2
for _snapshot_hash_file in ${_snapshots_dir}/*.SHA512; do

	_snapshot_file="${_snapshot_hash_file%.SHA512}"
	_snapshot_filename=$( basename "${_snapshot_file}" )

	_package=${_snapshot_filename%%-*}
	_package_1st_char=${_package:0:1}

	_t2_download_dir="${_env_dest}/usr/src/t2-src/download"
	_snapshot_dest="${_t2_download_dir}/mirror/${_package_1st_char}"

	# copy downloaded snapshot, so for local use the download is cached and sped up
	if ! ( mkdir -p "${_snapshot_dest}" && cp "${_snapshot_file}" "${_snapshot_dest}/" ); then

		error 3 "\nE: snapshot \`${_snapshot_file}' could not be moved to \`${_snapshot_dest}'. Cannot continue."
	else
		rm "${_snapshot_hash_file}"
	fi

	case ${_package} in

		binutils | gcc)
			_t2_package_base_dir="${_env_dest}/usr/src/t2-src/package/develop"
			_t2_template_package_base_dir="${_t2_template_base_dir}/package/develop"
			;;

		glibc)
			_t2_package_base_dir="${_env_dest}/usr/src/t2-src/package/base"
			_t2_template_package_base_dir="${_t2_template_base_dir}/package/base"
			;;

		*)
			error 4 "\nE: unknown package \`$_package'. Cannot continue."
			;;
	esac

	#echo -e "\nD: $_t2_package_base_dir $_t2_template_package_base_dir" 1>&2

	# remove actual package dir and replace it with our prepared template dir
	if ! ( rm -rf "${_t2_package_base_dir}/${_package}" && \
	       cp -rad "${_t2_template_package_base_dir}/${_package}" "${_t2_package_base_dir}/" ); then

		error 1 "\nE: problem when replacing actual package dir with prepared template dir. Cannot continue."
	fi

	# signal package build for build order
	touch "build_${_package}"
done
echo "OK" 1>&2

# place config
echo -n "I: placing target configuration... " 1>&2
_target_config=$( echo ${_t2_template_base_dir}/config/* )
_target_config_name=$( basename ${_target_config} )

if ! ( mkdir -p "${_env_dest}/usr/src/t2-src/config" && cp -rad "${_target_config}" "${_env_dest}/usr/src/t2-src/config/" ); then

	error 1 "\nE: problem when placing target configuration. Cannot continue without target configuration."
else
	echo "${_target_config_name}" > "target_config"
	echo "OK" 1>&2
fi

exit
