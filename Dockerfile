FROM php:7.4.0-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid
ARG private_key

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git \
  curl \
  libpng-dev \
  libonig-dev \
  libxml2-dev \
  zip \
  libzip-dev \
  unzip \
  libssh2-1-dev \
  libssh2-1 \
  openssh-client \
  mariadb-client

RUN pecl install -o -f redis \
&&  rm -rf /tmp/pear \
&&  docker-php-ext-enable redis \
&& pecl install ssh2 \
&& docker-php-ext-enable ssh2 

RUN pecl install xdebug-3.1.5 \
    && docker-php-ext-enable xdebug

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure zip
RUN docker-php-ext-install zip
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN echo xdebug.mode=coverage > /usr/local/etc/php/conf.d/xdebug.ini 

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
  chown -R $user:$user /home/$user

RUN mkdir ~/.ssh && \
  echo "Host *" > ~/.ssh/config && \
  echo "  StrictHostKeyChecking accept-new" >> ~/.ssh/config && \
  echo "  ControlMaster auto" >> ~/.ssh/config && \
  echo "  ControlPath ~/.ssh/%r@%h:%p" >> ~/.ssh/config

# Set working directory
WORKDIR /var/www/html
USER $user