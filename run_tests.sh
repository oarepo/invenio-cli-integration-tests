#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# Copyright (C) 2023 CESNET.
#
# invenio-cli-integration-tests is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.

set -e

echo -e "\ninvenio-cli-integration-tests/run_tests.sh"

echo "Disabled"; exit 0

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

# test invenio shell:
echo -e "\ninvenio shell, invenio_config's version.__version__):"
invenio shell --simple-prompt -c "from invenio_config import version; print (\"invenio_config version:\", version.__version__)"

# invenio index:
#echo -e "\nsearch-service GET:"
#curl -sX GET "http://127.0.0.1:9200" || cat /tmp/local-es.log
echo "invenio index check:"
invenio index check

# invenio run:
echo -e "\ninvenio run (testing REST):"
#export INVENIO_RECORDS_REST_DEFAULT_CREATE_PERMISSION_FACTORY='invenio_records_rest.utils:allow_all'
#export INVENIO_RECORDS_REST_DEFAULT_UPDATE_PERMISSION_FACTORY='invenio_records_rest.utils:allow_all'
#export INVENIO_RECORDS_REST_DEFAULT_DELETE_PERMISSION_FACTORY='invenio_records_rest.utils:allow_all'

#invenio run --cert ./ssl/test.crt --key ./ssl/test.key > invenio_run.log 2>&1 &
invenio-cli run > invenio_run.log 2>&1 &
INVEPID=$!
trap "kill $INVEPID &>/dev/null; cat invenio_run.log" EXIT
sleep 8

# test REST API:
echo -n "jq version:"; jq --version
./scripts/test_rest.sh

kill $INVEPID
trap - EXIT
echo -e "\ninvenio_run.log:"
cat invenio_run.log

#echo -e "\nsave requirements"
#REQFILE="upload/requirements-${REQUIREMENTS}.txt"
#pip freeze > $REQFILE
##./scripts/poetry2reqs.py | sed 's/\x0D$//' | grep -v '^pywin32==' > $REQFILE
#grep -F -e invenio= -e invenio-base -e invenio-search -e invenio-db $REQFILE

echo "Done."
