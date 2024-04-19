#!/bin/bash

for file in find src/contracts/src -type f; do
    echo "$file"
    echo "```"
    cat "$file"
    echo "```"
    echo
dones