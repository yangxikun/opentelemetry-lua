FROM openresty/openresty:1.19.9.1-centos7

RUN yum install -y gcc
RUN luarocks install api7-lua-resty-http 0.2.0
RUN luarocks install lua-protobuf 0.3.3
RUN luarocks install busted 2.0.0-1

RUN yum install -y cpanminus perl
RUN cpanm --notest Test::Nginx IPC::Run > build.log 2>&1 || (cat build.log && exit 1)

RUN yum install -y python3 python3-devel git
RUN pip3 install multidict attrs yarl async_timeout charset-normalizer idna_ssl aiosignal
RUN pip3 install aiohttp

