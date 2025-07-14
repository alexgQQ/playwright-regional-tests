#!/usr/bin/env bash

# Run our playwright tests and upload the result report to a bucket

set -ex

export ZONE=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/zone -H "Metadata-Flavor: Google")
export BUCKET_PATH=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/bucket_path -H "Metadata-Flavor: Google")

# Since this runs as a startup script there may be other
# startup processes that may need to finish up
sleep 60

cd /playwright-regional-tests/playwright
# The node docs frown on this as it's mostly for dev purposes
# and they recommend to just install locally and globally
# https://nodejs.org/en/blog/npm/npm-1-0-global-vs-local-installation/
# but for my use case it should be fine
npm link @playwright/test
# Restrict this to 1 worker to avoid any memory bottlenecks and
# the blob reporter so we can merge the results with others down the line
# or format them later as needed
export PLAYWRIGHT_BLOB_OUTPUT_NAME=report-${ZONE}.zip
npx playwright test --repeat-each 1 --workers 1 --reporter=blob

gsutil -m cp blob-report/*.zip gs://${BUCKET_PATH}
shutdown -h now
