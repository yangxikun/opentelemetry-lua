#!/bin/bash

################################################################################
# There's a test suite in the w3c/trace-context repo that we use against our
# code and nginx.conf
################################################################################

cd /opt
if [ ! -d "trace-context" ]; then
    git clone https://github.com/w3c/trace-context
fi
cd trace-context/test

# Run an individual test:
# HARNESS_DEBUG=1 python3 test.py http://127.0.0.1:80/test/e2e/trace-context TraceContextTest.test_traceparent_parent_id_too_short

# Run every test:
python3 test.py http://127.0.0.1:80/test/e2e/trace-context
