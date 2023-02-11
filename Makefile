.PHONY: doc format api-test
CONTAINER_ORCHESTRATOR ?= docker-compose
CONTAINER_ORCHESTRATOR_EXEC_OPTIONS := $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS)

openresty-dev:
	$(CONTAINER_ORCHESTRATOR) up -d openresty
	$(CONTAINER_ORCHESTRATOR) exec $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'luarocks make && nginx -s reload'

openresty-test-e2e:
	$(CONTAINER_ORCHESTRATOR) run -e PROXY_ENDPOINT=http://openresty/test/e2e --rm test-client

openresty-test-e2e-trace-context:
	$(CONTAINER_ORCHESTRATOR) exec $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash /opt/opentelemetry-lua/e2e-trace-context.sh

openresty-integration-test:
	$(CONTAINER_ORCHESTRATOR) exec $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'cd /opt/opentelemetry-lua && prove -r'

lua-unit-test:
	$(CONTAINER_ORCHESTRATOR) run --no-deps $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c './busted-runner'

openresty-build:
	$(CONTAINER_ORCHESTRATOR) build

doc:
	$(CONTAINER_ORCHESTRATOR) run $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'ldoc lib/opentelemetry/api'

check-format:
	$(CONTAINER_ORCHESTRATOR) run --no-deps $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- utils bash -c 'lua-format --check lib/opentelemetry/api/**/*.lua spec/api/**/*.lua'

format:
	$(CONTAINER_ORCHESTRATOR) run --no-deps $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- utils bash -c 'lua-format -i lib/opentelemetry/api/**/*.lua  spec/api/**/*.lua'

api-test:
	$(CONTAINER_ORCHESTRATOR) run --no-deps $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'busted -m "./lib/?.lua;./lib/?/?.lua;./lib/?/?/?.lua" ./spec/api'

generate-semantic-conventions:
	$(CONTAINER_ORCHESTRATOR) run --no-deps $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'pushd tmp && rm -rf opentelemetry-specification && git clone --depth=1 https://github.com/open-telemetry/opentelemetry-specification.git && popd && resty ./utils/generate_semantic_conventions.lua && lua-format -i lib/opentelemetry/semantic_conventions/trace/*.lua'
