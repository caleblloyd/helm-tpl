#!/bin/bash

cd "$(dirname "$0")"
cp ../../_toPrettyRawJson.tpl templates/_toPrettyRawJson.tpl

helm template .
