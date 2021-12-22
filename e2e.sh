#!/bin/bash

yum install -y python3 git
pip3 install aiohttp

cd /opt
if [ ! -d "trace-context" ]; then
    git clone https://github.com/w3c/trace-context
fi
cd trace-context/test
# python3 test.py http://127.0.0.1:80/test/e2e TraceContextTest.test_tracestate_all_allowed_characters
python3 test.py http://127.0.0.1:80/test/e2e
