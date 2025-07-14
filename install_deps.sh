#!/usr/bin/env bash

# Install Node 22 and the latest playwright package along
# with the test browsers and their related dependencies

set -ex

# Other startup process will use apt which can cause lock errors
# for the rest of the script, so lets give them some time to finish
sleep 60
# Leaving this here as we could watch for user locks but the locks
# get placed on various files so it needs more fleshing out
# while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
#   echo "Waiting for other software managers to finish..." 
#   sleep 1
# done

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -yq nodejs git

npm install -g @playwright/test@latest

npx playwright install-deps
npx playwright install

git clone https://github.com/alexgQQ/playwright-regional-tests.git

# We actually want this off after this is done as we don't want
# any writes happening to the disk when we make the related disk image
# plus it is an easy signal that it is complete
shutdown -h now
