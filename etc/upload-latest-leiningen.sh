#!/bin/bash

set -e

# This script searches for the latest Leiningen release on
# https://github.com/technomancy/leiningen and upload the
# artifact to all configured buckets.

# It's required to have gs3pload installed and configured
# to execute this script. Please check https://github.com/fern4lvarez/gs3pload
# for further information.

if [ -z "$DOMAIN" ]; then
    echo "Please set a DOMAIN var"
    exit 1
fi  

LATEST_LEIN_VERSION_URL="https://packages.${DOMAIN}/buildpack-clojure/leiningen-latest"

# Get current version of leiningen
CURRENT="$(curl --silent -L ${LATEST_LEIN_VERSION_URL})"
echo "---> Current version of leiningen: ${CURRENT}"

# Get latest leiningen version and compare it with the current
LATEST="$(curl --silent -I https://github.com/technomancy/leiningen/releases/latest | grep Location | sed 's#.*/##' |  tr -d '\r')"
if [[ ${LATEST} < ${CURRENT} ]] || [[ ${LATEST} == ${CURRENT} ]]; then
	echo "No newer version found. Exiting."
	exit 1
fi

# Upload to buckets
echo "---> Newer version found... ${LATEST}"
FILENAME="leiningen-${LATEST}-standalone"
echo ${LATEST} > leiningen-latest
gs3pload push packages/buildpack-clojure leiningen-latest -p

# Download the latest version and upload it to the bucket
echo "---> Downloading leiningen version ${LATEST}..."
wget https://github.com/technomancy/leiningen/releases/download/$LATEST/${FILENAME}.zip
mv ${FILENAME}.zip ${FILENAME}.jar
gs3pload push packages/buildpack-clojure ${FILENAME}.jar -p

# Cleanup
rm leiningen-latest
rm ${FILENAME}.jar

echo "Success! ${LATEST} version uploaded."
