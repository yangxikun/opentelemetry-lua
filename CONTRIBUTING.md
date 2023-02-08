# Contributing

## Tests

There are a few different types of tests in this repo, which can all be run via the Makefile.

### Integration tests

There are integration tests in the `t/` directory. These use Perl's `Test::NGINX` framework, as described in the [Programming Openresty Book](https://openresty.gitbooks.io/programming-openresty/content/testing/test-nginx.html). To run these tests, you first must start a working openresty server, which is configured to use the code in the repo (`make openresty-dev`). Then, you can run tests using `make openresty-unit-test`.

```
make openresty-dev
make openresty-unit-test
```

To pick up code changes, you need to re-run `luarocks make && nginx -s reload` inside the `openresty` container started by `make openresty-dev`.

### Tracecontext tests

There's a test suite in the [w3c/trace-context repo](https://github.com/w3c/trace-context/) that we run against our code and nginx.conf. To run these:

```
make openresty-dev
make openresty-test-e2e-trace-context
```

### Unit tests

There's two sets of unit tests oriented around different runtimes.

```
# Run tests oriented around Openresty
make lua-unit-test

# Run tests that should pass in any Lua runtime
make api-test
```


## Community

This project is not officially part of the OpenTelemetry org yet, but you can find some folks in this [Slack channel](https://cloud-native.slack.com/archives/C048T6NFQTY) in [CNCF Slack](https://communityinviter.com/apps/cloud-native/cncf).
