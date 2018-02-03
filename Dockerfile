FROM php:7.1-fpm-alpine
MAINTAINER Simon Erhardt <hello@rootlogin.ch>

ARG NEXTCLOUD_GPG="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"
ARG NEXTCLOUD_VERSION=13.0.0RC4
ARG UID=1501
ARG GID=1501

RUN set -ex \
  && apk add --update \
  alpine-sdk \
  autoconf \
  bash \
  gnupg \
  icu-dev \
  icu-libs \
  libjpeg-turbo \
  libjpeg-turbo-dev \
  libldap \
  libmcrypt \
  libmcrypt-dev \
  libmemcached \
  libmemcached-dev \
  libpng \
  libpng-dev \
  nginx \
  openldap-dev \
  openssl \
  pcre \
  pcre-dev \
  postgresql-dev \
  postgresql-libs \
  samba-client \
  sudo \
  supervisor \
  tar \
  tini \
  wget \

# PHP Extensions
# https://docs.nextcloud.com/server/9/admin_manual/installation/source_installation.html
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-configure ldap \
  && docker-php-ext-install gd exif intl mbstring mcrypt ldap mysqli opcache pdo_mysql pdo_pgsql pgsql zip \
  && pecl install APCu-5.1.8 \
  && pecl install memcached-3.0.2 \
  && pecl install redis-3.1.1 \
  && docker-php-ext-enable apcu redis memcached \

# Remove dev packages
  && apk del \
    alpine-sdk \
    autoconf \
    icu-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    openldap-dev \
    pcre-dev \
    postgresql-dev \
  && rm -rf /var/cache/apk/* \

  # Add user for nextcloud
  && addgroup -g ${GID} nextcloud \
  && adduser -u ${UID} -h /opt/nextcloud -H -G nextcloud -s /sbin/nologin -D nextcloud \
  && mkdir -p /opt/nextcloud \

# Download Nextcloud
  && cd /tmp \
  && wget -q https://github.com/nextcloud/server/archive/v13.0.0RC4.tar.gz \

# Extract
  && tar xjf v13.0.0RC4.tar.gz --strip-components=1 -C /opt/nextcloud \
# Remove nextcloud updater for safety
  && rm -rf /opt/nextcloud/updater \
  && rm -rf /tmp/* /root/.gnupg

COPY root /

RUN chmod +x /usr/local/bin/run.sh /usr/local/bin/occ /etc/periodic/15min/nextcloud

VOLUME ["/data"]

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/run.sh"]
