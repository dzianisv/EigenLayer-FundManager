#!/bin/bash

set -eu


forge script \
     --broadcast --rpc-url "${ETH_RPC_URL}" \
     --private-key "${ETH_PRIVATE_KEY}" \
     script/TestDeposit.sol:TestDeposit