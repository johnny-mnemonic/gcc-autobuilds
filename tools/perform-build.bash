#!/bin/bash

. /etc/profile

if [[ -e "/build-order.bash" ]]; then

	# execute build order
	if /build-order.bash; then

		exit 0
	else
		exit 1
	fi
fi

exit
