#!/bin/bash

cd "$(dirname "$0")"
cp ../../_jsonpatch.tpl templates/_jsonpatch.tpl
cp ../../_tplYaml.tpl templates/_tplYaml.tpl

helm template .
