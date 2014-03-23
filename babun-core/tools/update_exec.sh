#!/bin/bash
set -o pipefail
set -e
set -f

babun="/usr/local/etc/babun"

# install/update plugins
"$babun"/source/babun-core/plugins/install.sh || { echo "ERROR: Could not update babun!"; exit -2; }
 
# install/update home folder
"$babun"/source/babun-core/plugins/install_home.sh || { echo "ERROR: Could not update home folder!"; exit -3; }

# set the newest version marker
cat "$babun/source/babun.version" > "$babun/installed/babun"