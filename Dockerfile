# vim:set et ts=2 sw=2 syntax=dockerfile:

FROM       docker.xlands-inc.com/baoyu/debian
MAINTAINER djluo <dj.luo@baoyugame.com>

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && apt-get install -y apache2 apache2-mpm-worker apache2-utils libapache2-svn subversion \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf usr/share/locale \
    && rm -rf usr/share/man    \
    && rm -rf usr/share/doc    \
    && rm -rf usr/share/info   \
    && find var/lib/apt -type f -exec rm -fv {} \;

COPY ./conf/00-apache2.conf /etc/apache2/apache2.conf
COPY ./entrypoint.pl        /entrypoint.pl
COPY ./conf/access.d/example     /svnroot/example/example
COPY ./conf/vhost.d/example.conf /svnroot/example/example.conf

ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/sbin/apache2", "-DFOREGROUND"]
