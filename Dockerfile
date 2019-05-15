FROM php:7.1-fpm

ENV TERM=xterm

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libxslt-dev \
        libmcrypt-dev \
        libpng-dev \
        git \
        mysql-client \
        msmtp \
        zlib1g-dev \
        cron \
        nano \
        libcurl4-gnutls-dev \
        libicu-dev \
        openssl \
        wget \
        bash-completion \
    && docker-php-ext-install -j$(nproc) iconv mcrypt pdo_mysql mysqli xsl opcache zip curl intl soap json pdo bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

RUN pecl install redis xdebug && docker-php-ext-enable redis xdebug

RUN curl -sL https://files.magerun.net/n98-magerun.phar -o /usr/local/bin/n98-magerun \
    && chmod +x /usr/local/bin/n98-magerun \
    && /usr/local/bin/n98-magerun self-update

RUN wget -O /etc/bash_completion.d/n98-magerun.phar https://github.com/netz98/n98-magerun/blob/master/res/autocompletion/bash/n98-magerun.phar.bash

RUN curl -sL https://files.magerun.net/n98-magerun2.phar -o /usr/local/bin/n98-magerun2 \
    && chmod +x /usr/local/bin/n98-magerun2 \
    && /usr/local/bin/n98-magerun2 self-update

RUN curl -sL https://getcomposer.org/composer.phar -o /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && /usr/local/bin/composer self-update

RUN wget -O /etc/bash_completion.d/n98-magerun2.phar https://github.com/netz98/n98-magerun2/blob/develop/res/autocompletion/bash/n98-magerun2.phar.bash


RUN { \
    echo '# enable bash completion in interactive shells'; \
    echo 'if ! shopt -oq posix; then'; \
    echo '  if [ -f /usr/share/bash-completion/bash_completion ]; then'; \
    echo '    . /usr/share/bash-completion/bash_completion'; \
    echo '  elif [ -f /etc/bash_completion ]; then'; \
    echo '    . /etc/bash_completion'; \
    echo '  fi'; \
    echo 'fi'; \
    } > /root/.bashrc

RUN { \
        echo 'alias mr=/usr/local/bin/n98-magerun'; \
        echo 'alias mr2=/usr/local/bin/n98-magerun2'; \
        } > /etc/profile.d/00-aliases.sh

# Speed up install composer libraries
RUN composer global require "hirak/prestissimo:^0.3"

RUN curl -sL https://raw.githubusercontent.com/colinmollenhour/modman/master/modman -o /usr/local/bin/modman \
    && chmod +x /usr/local/bin/modman

RUN echo 'xdebug.profiler_enable_trigger = On' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo 'xdebug.profiler_output_dir = /tmp' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo 'xdebug.profiler_output_name = xdebug.out.%p' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

ADD ./php/custom.ini /usr/local/etc/php/conf.d/custom.ini
RUN touch /var/log/msmtp.log && chmod a+rw /var/log/msmtp.log

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN apt-get install -y ghostscript

RUN apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /project
