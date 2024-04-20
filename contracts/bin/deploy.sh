#!/bin/bash

set -eu

if [ -n "${BLOCK_EXPLORER_API_KEY:-}" ]; then
    args="--verify  --etherscan-api-key $BLOCK_EXPLORER_API_KEY"
else
    args=
fi

forge script \
     --broadcast --rpc-url "${ETH_RPC_URL}" \
     --private-key "${ETH_PRIVATE_KEY}" \
     $args \
     script/Deploy.sol