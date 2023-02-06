#!/bin/bash

cd "$(dirname "$0")"
cp ../_jsonpatch.tpl templates/_jsonpatch.tpl

helm template .
