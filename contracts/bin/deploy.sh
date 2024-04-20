#!/bin/bash

set -eu

forge script \
     --broadcast --rpc-url "${ETH_RPC_URL}" \
     --private-key "${ETH_PRIVATE_KEY}" \
     --verify   --etherscan-api-key "$BLOCK_EXPLORER_API_KEY"
    script/Deploy.sol:$*