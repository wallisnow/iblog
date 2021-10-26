#!/bin/bash

publish_to_blog="${1}"

def_msg=""
additional_msg="${2:-$def_msg}"

if [ "$publish_to_blog" == "y" ]; then
  hexo g -d
elif [ "$publish_to_blog" == "n" ]; then
  hexo g
else
  echo "Only push code to master, use 'y' or 'n' to deploy the blog"
fi

git add .
git commit -m "update code in $(date): ${additional_msg}"
git push
