#!/bin/bash

temp = ( $(find -iname *.fb2 -exec file '{}' \; | grep Zip | cut -d: -f1) )

for arrfile in "${temp[@]}"
do
  filename="${arrfile##*/}"
  dir="${arrfile:0:${#arrfile} - ${#filename}}"
  base="${filename%.[^.]*}"
  ext="${filename:${#base} + 1}"
  if [[ -z "$base" && -n "$ext" ]]; then
    base=".$ext"
    ext=""
  fi
  
  zipfile=$dir$base.zip
  
  mv arrfile $zipfile
  
  7z e '-i!*fb2' -o $dir $zipfile
  
done

