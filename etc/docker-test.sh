#!/bin/bash

DIR=$(cd $(dirname $0)/..; pwd)

docker run -it -e DOMAIN=devcctrl.com -e PAAS_VENDOR=cloudControl -v $DIR:/app/buildpack:ro heroku/testrunner
