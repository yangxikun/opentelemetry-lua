FROM openresty/openresty:1.21.4.1-0-centos

RUN yum install -y gcc
RUN yum -y --enablerepo=powertools install libyaml-devel libffi-devel
RUN luarocks install lua-resty-http 0.16.1-0
RUN luarocks install lua-protobuf 0.3.3
RUN luarocks install busted 2.0.0-1
RUN luarocks --server=http://rocks.moonscript.org install lyaml

RUN yum install -y cpanminus perl
RUN cpanm --notest Test::Nginx IPC::Run > build.log 2>&1 || (cat build.log && exit 1)

RUN yum install -y python3 python3-devel git
RUN pip3 install multidict attrs yarl async_timeout charset-normalizer idna_ssl aiosignal
RUN pip3 install aiohttp

WORKDIR /opt/opentelemetry-lua
