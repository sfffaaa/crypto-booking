#!/usr/bin/env bash

# Exit script as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

cleanup() {
  # Kill the testrpc instance that we started (if we started one and if it's still running).
  if [ -n "$testrpc_pid" ] && ps -p $testrpc_pid > /dev/null; then
    kill -9 $testrpc_pid
  fi
}

if [ "$SOLIDITY_COVERAGE" = true ]; then
  testrpc_port=8555
else
  testrpc_port=8545
fi

testrpc_running() {
  nc -z localhost "$testrpc_port"
}

start_testrpc() {
  # We define 10 accounts with balance lots of ether, needed for high-value tests.
  local accounts=(
    --account="0xe8280389ca1303a2712a874707fdd5d8ae0437fab9918f845d26fd9919af5a92,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0xed095a912033d26dc444d2675b33414f0561af170d58c33f394db8812c87a764,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0xf5556ca108835f04cd7d29b4ac66f139dc12b61396b147674631ce25e6e80b9b,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0xd1bea55dd05b35be047e409617bc6010b0363f22893b871ceef2adf8e97b9eb9,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0xfc452929dc8ffd956ebab936ed0f56d71a8c537b0393ea9da4807836942045c5,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0x12b8b2fe49596ab7f439d324797f4b5457b5bd34e9860b08828e4b01af228d93,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0x2ed88e3846387d0ae4cca96637df48c201c86079be64d0a17bf492058db6c6eb,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0x8c6690649d0b31790fceddd6a59decf2b03686bed940a9b85e8105c5e82f7a86,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0xf809d1a2969bec37e7c14628717092befa82156fb2ebf935ac5420bc522f0d29,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0x38062255973f02f1b320d8c7762dd286946b3e366f73076995dc859a6346c2ec,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
    --account="0x35b5042e809eab0db3252bad02b67436f64453072128ee91c1d4605de70b27c1,10000000000000000000000000000000000000000000000000000000000000000000000000000000"
  )

  if [ "$SOLIDITY_COVERAGE" = true ]; then
    node_modules/.bin/testrpc-sc --gasLimit 0xfffffffffff --port "$testrpc_port" "${accounts[@]}" > /dev/null &
  else
    node_modules/.bin/ganache-cli  --gasLimit 0xfffffffffff "${accounts[@]}" > /dev/null &
  fi

  testrpc_pid=$!
}

if testrpc_running; then
  echo "Using existing testrpc instance"
else
  echo "Starting our own testrpc instance"
  start_testrpc
fi

if [ "$SOLIDITY_COVERAGE" = true ]; then
  node_modules/.bin/solidity-coverage

  if [ "$CONTINUOUS_INTEGRATION" = true ]; then
    cat coverage/lcov.info | node_modules/.bin/coveralls
  fi
else
  node_modules/.bin/truffle test "$@"
fi
