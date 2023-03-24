#!/bin/bash

cd "$(dirname "$0")"
cp ../../_jsonpatch.tpl templates/_jsonpatch.tpl
cp ../../_tplValues.tpl templates/_tplValues.tpl

helm template .
