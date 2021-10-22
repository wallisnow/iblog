#!/bin/bash

def_msg=""
additional_msg="${1:-$def_msg}"

git add .
git commit -m "update code in $(date): ${additional_msg}"
git push