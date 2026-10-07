FROM openresty/openresty:1.31-alpine-fat

RUN apk add --no-cache gcc
RUN apk add --no-cache yaml-dev libffi-dev
RUN luarocks install lua-resty-http 0.16.1-0
RUN luarocks install lua-protobuf 0.5.2
RUN luarocks install net-url 1.1-1
RUN luarocks install busted 2.0.0-1
RUN luarocks --server=http://rocks.moonscript.org install lyaml

RUN apk add --no-cache perl perl-dev perl-app-cpanminus
RUN cpanm --notest Test::Nginx IPC::Run > build.log 2>&1 || (cat build.log && exit 1)

RUN apk add --no-cache python3 python3-dev py3-pip git
RUN pip3 install --break-system-packages multidict attrs yarl async_timeout charset-normalizer aiosignal
RUN pip3 install --break-system-packages aiohttp

WORKDIR /opt/opentelemetry-lua
