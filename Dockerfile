FROM openresty/openresty:1.19.9.1-centos7-amd64

RUN yum install -y gcc
RUN luarocks install api7-lua-resty-http 0.2.0
RUN luarocks install lua-protobuf 0.3.3

RUN yum install -y perl-CPAN
RUN cpan;exit 0
ENV PERL_LOCAL_LIB_ROOT "$PERL_LOCAL_LIB_ROOT:/root/perl5"
ENV PERL_MB_OPT "--install_base /root/perl5"
ENV PERL_MM_OPT "INSTALL_BASE=/root/perl5"
ENV PERL5LIB "/root/perl5/lib/perl5:$PERL5LIB"
ENV PATH "/root/perl5/bin:$PATH"
RUN perl -MCPAN -e 'install Bundle::LWP'
RUN cpan Test::Nginx
