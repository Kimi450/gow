#!/bin/bash

set -e

function join_by { local IFS="$1"; shift; echo "$*"; }

declare -A group_map

for dev in "$@"; do
    # Only process $dev if it's a character device
    if [ ! -c "$dev" ]; then
        continue
    fi

    dev_group=$(stat -c "%G" "$dev")
    dev_gid=$(stat -c "%g" "$dev")

    if [ "$dev_group" = "UNKNOWN" ]; then
        new_name="gow-gid-$dev_gid"
        # We only have a GID for this group; create a named group for it
        # this isn't 100% necessary but it prevents some useless noise in the console
        sudo groupadd -g $dev_gid "$new_name"
        group_map[$new_name]=1
    else
        # the group already exists; just add it to the list
        group_map[$dev_group]=1
    fi
done

groups=$(join_by "," "${!group_map[@]}")
if [ "$groups" != "" ]; then
    echo "Adding user '$(whoami)' to groups: $groups"

    sudo usermod -G $groups $(whoami)
else
    echo "Not modifying user groups ($groups)"
fi
