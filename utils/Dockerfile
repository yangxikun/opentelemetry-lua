FROM openresty/openresty:1.21.4.1-0-centos

RUN yum install -y gcc gcc-c++ git cmake
RUN luarocks install busted 2.0.0-1
RUN luarocks install ldoc 1.4.6-2
RUN luarocks install --server=https://luarocks.org/dev luaformatter

WORKDIR /opt/opentelemetry-lua
