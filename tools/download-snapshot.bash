#!/bin/bash

# download snapshot

_snapshots_dir="$SNAPSHOTS"

_snapshot_url="$1"

if [[ "$1" == "" ]]; then

	echo "usage: $( basename $0 ) <SNAPSHOT_URL>" 1>&2
	exit 64
fi

pushd "${_snapshots_dir}" &>/dev/null

# Try to download snapshot
if ! wget -c "$_snapshot_url" 2>/dev/null; then

	echo "E: download of \`$_snapshot_url' failed. Cannot continue." 1>&2
	exit 2
fi

_snapshot_filename=$( basename $_snapshot_url )

# Check with SHA512 hash
if ! sha512sum -c ${_snapshot_filename}.SHA512 &>/dev/null; then

	echo "E: downloaded snapshot (\`$_snapshot_url') does not match hash value (\`$( cat ${_snapshot_filename}.SHA512 )'). Won't continue." 1>&2
	exit 3
fi

echo "${_snapshots_dir}/${_snapshot_filename}"

popd &>/dev/null

exit
