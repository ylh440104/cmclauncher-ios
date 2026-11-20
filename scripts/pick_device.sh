#!/bin/sh
set -e
xcrun simctl list devices available -j | python3 -c '
import json
import sys

data = json.load(sys.stdin)["devices"]
for runtime in sorted(data, reverse=True):
    for device in data[runtime]:
        if "iPhone" in device["name"]:
            print(device["udid"])
            sys.exit(0)
sys.exit(1)
'