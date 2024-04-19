#!/bin/bash

for file in $(find contracts/src -type f); do
    echo "$file"
    echo '```'
    cat "$file"
    echo '```'
    echo
done