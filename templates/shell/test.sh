#!/usr/bin/env bash
set -euo pipefail

output="$(./bin/app)"
[[ "$output" == "hello" ]]
