#!/bin/sh
# This script bootstraps the Basidiocarp ecosystem.
# It installs stipe (the ecosystem manager) and then runs stipe setup.
set -eu
curl -fsSL https://raw.githubusercontent.com/basidiocarp/stipe/main/install.sh | sh
exec stipe setup "$@"
