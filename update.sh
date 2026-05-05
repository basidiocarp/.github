#!/bin/sh
# Update all Basidiocarp ecosystem tools.
set -eu
exec stipe update --all "$@"
