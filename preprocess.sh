#!/bin/sh
cat $1 | python madcit/src/mexec.py -f buildmetadatadb.sql -w $2
