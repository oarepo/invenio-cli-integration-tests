#!/bin/bash
# -*- coding: utf-8 -*-
#
# Copyright (C) 2023 CESNET.
#
# invenio-cli-integration-tests is free software; you can redistribute it and/or modify it
# under the terms of the MIT License; see LICENSE file for more details.

set -e

err() { printf "$0[error]: %s\n" "$*" >&2; exit 2; }

#REST_URL="https://${INVENIO_SERVER_NAME}/api/records"
REST_URL="https://127.0.0.1:5000/api/records"
DATE=$(date '+%y%m%d-%H%M%S')
TESTUSER_EMAIL="noreply@cesnet.cz"

echo -n "  user create: "
invenio users create "$TESTUSER_EMAIL" --password 123456
echo "  OK"
echo -n "  token create: "
TOKTXT=$(date '+%y%m%d-%H%M%S')
TOK=$(invenio tokens create -u "$TESTUSER_EMAIL" -n "test-$TOKTXT")
echo "  OK"

echo -n "  list records: "
RESULT=$(curl -sk -XGET "$REST_URL"); echo "status: $?"
#echo ">$RESULT<"
VAL0=$(echo "$RESULT" | jq '.hits.total')
#[[ "$VAL" == "0" ]] || err "unexpected records (total:\"$VAL\"/0)"
echo "  orig. number of records: $VAL0"
sleep 1

DATAFILE1="../tests/record1.json"
DATAFILE1U="../tests/record1u.json"
DATAFILE2="../tests/record2.json"

echo -n "  ADD (POST) new record ($REST_URL): "
RESULT=$(curl -sk -H "authorization: Bearer $TOK" -H 'Content-Type:application/json' -d "@$DATAFILE1" -XPOST "$REST_URL"); echo "status: $?"
echo ">$RESULT<"
VAL=$(echo "$RESULT" | jq -r '.id')
[[ "$VAL" == "null" ]] && err "wrong id (\"$VAL\"/0)"
ID1=$VAL
echo "  OK id: $ID1"
VAL=$(echo "$RESULT" | jq -r '.links.publish')
PUBLISH_URL="$VAL"
VAL=$(echo "$RESULT" | jq -r '.links.self')
DRAFT_URL="$VAL"

sleep 1
echo -n "  UPDATE (PUT) existing record ($DRAFT_URL): "
RESULT=$(curl -sk -H "authorization: Bearer $TOK" -H 'Content-Type:application/json' -d "@$DATAFILE1U" -XPUT "$DRAFT_URL"); echo "status: $?"
echo "updated: >$RESULT<"
VAL=$(echo "$RESULT" | jq -r '.id')
[[ "$VAL" == "$ID1" ]] || err "wrong id (\"$VAL\"/$ID1)"
VAL=$(echo "$RESULT" | jq -r '.metadata.title')
[[ "$VAL" == "Title test Record 1 update A" ]] || err "wrong title (\"$VAL\"/\"Title test Record 1 update A\")"
echo "  OK updated, new title: \"$VAL\""

sleep 1
echo -n "  publish (POST) 1st record ($PUBLISH_URL): "
RESULT=$(curl -sk -H "authorization: Bearer $TOK" -H 'Content-Type:application/json' -XPOST "$PUBLISH_URL"); echo "status: $?"
echo "published: >$RESULT<"
VAL=$(echo "$RESULT" | jq -r '.is_published')
[[ "$VAL" == "true" ]] || err "wrong is_published (\"$VAL\"/0)"

sleep 2
RESULT=$(curl -sk -XGET "$REST_URL"); echo "status: $?"
VAL=$(echo "$RESULT" | jq '.hits.total')
[[ "$VAL" == "$((VAL0+1))" ]] || err "wrong number of records (total:\"$VAL\"/$((VAL0+1)))"
echo "  OK total: $VAL"

sleep 1
echo -n "  search records ($REST_URL?q=update): "
RESULT=$(curl -sk -XGET "$REST_URL?q=update"); echo "status: $?"
VAL=$(echo "$RESULT" | jq -r '.hits.total')
#[[ "$VAL" == "1" ]] || err "wrong number of records (total:\"$VAL\"/1)"
echo "  OK total: $VAL"
VAL=$(echo "$RESULT" | jq -r '.hits.hits[]|select(.id == "'"$ID1"'").metadata.title')
[[ "$VAL" == "Title test Record 1 update A" ]] || err "wrong title (\"$VAL\"/\"Title test Record 1 update A\")"
echo "  OK found title: \"$VAL\""


echo -n "  ADD (POST) 2nd new record ($REST_URL): "
RESULT=$(curl -sk -H "authorization: Bearer $TOK" -H 'Content-Type:application/json' -d "@DATAFILE2" -XPOST "$REST_URL"); echo "status: $?"
echo ">$RESULT<"
VAL=$(echo "$RESULT" | jq -r '.id')
[[ "$VAL" == "null" ]] && err "wrong id (\"$VAL\"/0)"
echo "  OK id: $VAL"
VAL=$(echo "$RESULT" | jq -r '.links.publish')
PUBLISH_URL="$VAL"
VAL=$(echo "$RESULT" | jq -r '.links.self')
DRAFT_URL="$VAL"

#echo -n "  DELETE record: "
#RESULT=$(curl -sk -H "authorization: Bearer $TOK" -XDELETE "$REST_URL"); echo "status: $?"
#[[ "$RESULT" == "" ]] || err "error (\"$RESULT\"/1)"
#echo "  OK deleted"
#sleep 1
#echo -n "  list records: "
#RESULT=$(curl -sk -XGET "$REST_URL"); echo "status: $?"
#VAL=$(echo "$RESULT" | jq -r '.hits.total')
##[[ "$VAL" == "1" ]] || err "wrong number of records (total:\"$VAL\"/1)"
#echo "  OK total: $VAL"
#VAL=$(echo "$RESULT" | jq -r '.hits.hits[]|select(.id == "'"$ID2"'").metadata.title')
#[[ "$VAL" == "Test Record 2" ]] || err "wrong title (\"$VAL\"/\"Test Record 2\")"

sleep 1
echo -n "  DELETE 2nd record ($DRAFT_URL): "
RESULT=$(curl -sk -H "authorization: Bearer $TOK" -XDELETE "$DRAFT_URL"); echo "status: $?"
[[ "$RESULT" == "" ]] || err "error (\"$RESULT\"/1)"
echo "  OK deleted"

sleep 1
echo -n "  check deleted ($DRAFT_URL): "
RESULT=$(curl -sk -H "authorization: Bearer $TOK" -XGET "$DRAFT_URL"); echo "status: $?"
VAL=$(echo "$RESULT" | jq -r '.status')
[[ "$VAL" == "404" ]] || err "wrong status (\"$VAL\"/404)"
echo "  OK"

#sleep 1
#echo -n "  list records: "
#RESULT=$(curl -sk -XGET "$REST_URL"); echo "status: $?"
#VAL=$(echo "$RESULT" | jq -r '.hits.total')
##[[ "$VAL" == "0" ]] || err "wrong number of records (total:\"$VAL\"/0)"
#echo "  OK total: $VAL"
#sleep 1

echo -n "  token delete: "
invenio tokens delete -u "$TESTUSER_EMAIL" -n "test-$TOKTXT" --force
echo "  OK Done."
