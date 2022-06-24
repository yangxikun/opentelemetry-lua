CONTAINER_ORCHESTRATOR ?= docker-compose
CONTAINER_ORCHESTRATOR_EXEC_OPTIONS := $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS)

openresty-dev:
	$(CONTAINER_ORCHESTRATOR) up -d openresty
	$(CONTAINER_ORCHESTRATOR) exec $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'cd /opt/opentelemetry-lua && luarocks make && nginx -s reload'

openresty-test-e2e:
	$(CONTAINER_ORCHESTRATOR) run -e PROXY_ENDPOINT=http://openresty/test/e2e --use-aliases --rm test-client

openresty-test-e2e-trace-context:
	$(CONTAINER_ORCHESTRATOR) exec $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash /opt/opentelemetry-lua/e2e-trace-context.sh

openresty-unit-test:
	$(CONTAINER_ORCHESTRATOR) exec $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty bash -c 'cd /opt/opentelemetry-lua && prove -r'

lua-unit-test:
	$(CONTAINER_ORCHESTRATOR) run $(CONTAINER_ORCHESTRATOR_EXEC_OPTIONS) -- openresty-test bash -c 'cd /opt/opentelemetry-lua && busted --lpath="./lib/?.lua;./lib/?/?.lua;./lib/?/init.lua"' .

openresty-build:
	$(CONTAINER_ORCHESTRATOR) build
