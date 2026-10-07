FROM openresty/openresty:1.31-alpine-fat

RUN apk add --no-cache gcc g++ git cmake
RUN luarocks install busted 2.0.0-1
RUN luarocks install ldoc 1.4.6-2
RUN luarocks install --server=https://luarocks.org/dev luaformatter

WORKDIR /opt/opentelemetry-lua
