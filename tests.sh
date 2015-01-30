#!/bin/bash
set -e
. assert.sh

assert "./docksend.sh" "usage: ./docksend.sh [-v docker_volume] [-i ssh_identity_file] [user@]hostname docker_image [command]"
assert_raises "./docksend.sh" 1
assert_raises "./docksend.sh -v" 3
assert_raises "./docksend.sh -x" 4
assert_end regression
