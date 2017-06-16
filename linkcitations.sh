#!/bin/sh
a=$PWD
cd $1
python $a"/"madcit/src/mterm.py $a"/"$2 < $a"/"citationquery.sql
cd $a
