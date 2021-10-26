#!/bin/bash

publish_to_blog="${2:-"n"}"

def_msg=""
additional_msg="${1:-$def_msg}"

if [ "$publish_to_blog" == "y" ]; then
  hexo g -d
elif [ "$publish_to_blog" == "n" ]; then
  hexo g
else
  echo "Unrecognized command for hexo deploy!, only 'y' or 'n' should be applied"
fi

git add .
git commit -m "update code in $(date): ${additional_msg}"
git push
