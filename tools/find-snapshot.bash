#!/bin/bash

# find latest snapshot

# points to worktree with hashes of already built tool snapshots
#
# past-builds/<PACKAGE>/<HASH>
_past_builds_worktree="$PAST_BUILDS"

_snapshots_dir="$SNAPSHOTS"

_url_file="$1"

if [[ "$1" == "" ]]; then

	echo "usage: $( basename $0 ) <URL_FILE>"
	exit 64
fi

_url_file_name=$( basename "$_url_file" )

_package=${_url_file_name%%-*}

while read _url; do

	_base_url=$( dirname ${_url} )

	_exit_code=0

	read _snapshot_sha512 _snapshot_filename <<-EOM
	$( wget "$_url" -O - 2>/dev/null | grep ${_package} )
	EOM

	if [[ "$_snapshot_sha512" == "" || \
	      "$_snapshot_filename" == "" ]]; then

		# something went wrong, so try next URL - if available
		echo "E: either hash or filename empty. Trying another URL - if available." 1>&2
		_exit_code=2
		continue
	fi

	if [[ -e "${_past_builds_worktree}/${_package}/${_snapshot_sha512}" ]]; then

		# already built, ignore
		_exit_code=1
		continue
	else
		# new snapshot found
		mkdir -p "${_snapshots_dir}"
		echo "${_snapshot_sha512} ${_snapshot_filename}" > "${_snapshots_dir}/${_snapshot_filename}.SHA512"

		echo "${_base_url}/${_snapshot_filename}"
		break
	fi
done < "$_url_file"

exit ${_exit_code}
