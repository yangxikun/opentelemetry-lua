#!/usr/bin/env bash

FILES="benchmark/*.lua"
for f in $FILES
do
  if [ -f "$f" ]
  then
    resty -I /opt/opentelemetry-lua/lib "$f"
  fi
done
