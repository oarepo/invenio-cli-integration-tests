#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# Copyright (C) 2023 CESNET.
#
# invenio-cli-integration-tests is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.

set -e

echo -e "\ninvenio-cli-integration-tests/run_tests.sh"

#function cleanup(){
#  eval "$(docker-services-cli down --env)"
#}
#trap cleanup EXIT

# start services:
#ENV0="$(printenv)"
#echo "docker-services-cli up (DB:$DB; SEARCH:$SEARCH)"
#eval "$(docker-services-cli up --db ${DB:-postgresql} --search ${SEARCH:-elasticsearch7} --mq ${MQ:-redis} --env)"
#ENV1="$(printenv)"
#echo "env diff:"
#diff <(echo "$ENV0") <(echo "$ENV1") || true
#echo ""

echo "### venv activate:"
. venv/bin/activate
ls -l my-site
cd my-site
pwd

# test invenio shell:
echo -e "\n### invenio shell, invenio_config's version.__version__):"
invenio shell --simple-prompt -c "from invenio_config import version; print (\"invenio_config version:\", version.__version__)"

# invenio index:
#echo -e "\nsearch-service GET:"
#curl -sX GET "http://127.0.0.1:9200" || cat /tmp/local-es.log
echo -e "\n### invenio index check:"
invenio index check

# invenio run:
echo -e "\ninvenio-cli run:"
invenio-cli run > invenio_run.log 2>&1 &
INVEPID=$!
trap "kill $INVEPID &>/dev/null; cat invenio_run.log" EXIT
sleep 8

# test HTTP UI:
echo -e "\ntesting HTTP UI:"
curl -sk -XGET "https://127.0.0.1:5000/" | grep "You've successfully installed InvenioRDM"

# test REST API:
echo -e "\ntesting REST API:"
echo -n "jq version:"; jq --version
../scripts/test_rest.sh

kill $INVEPID
trap - EXIT
echo -e "\ninvenio_run.log:"
cat invenio_run.log

#echo -e "\nsave requirements"
#REQFILE="upload/requirements-${REQUIREMENTS}.txt"
#pip freeze > $REQFILE
##./scripts/poetry2reqs.py | sed 's/\x0D$//' | grep -v '^pywin32==' > $REQFILE
#grep -F -e invenio= -e invenio-base -e invenio-search -e invenio-db $REQFILE

#echo -e "\nRemaining part disabled"; exit 0
echo "Done."
