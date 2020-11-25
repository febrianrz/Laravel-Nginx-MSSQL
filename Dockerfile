FROM php:7.2.29-fpm

# Arguments defined in docker-compose.yml
ARG user
ARG uid

COPY src/composer.lock src/composer.json /var/www/html/

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip
    
RUN apt-get install -y \
        libzip-dev \
        zip \
  && docker-php-ext-install zip

RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd

# SQLServer Ext
RUN apt-get -y install unixodbc-dev
RUN pecl install sqlsrv pdo_sqlsrv

# ODBC
RUN apt-get update && apt-get install -y locales unixodbc libgss3 odbcinst \
    devscripts debhelper dh-exec dh-autoreconf libreadline-dev libltdl-dev \
    unixodbc-dev wget unzip \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-install pdo \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Add Microsoft repo for Microsoft ODBC Driver 17 for Linux
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/9/prod.list > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update && ACCEPT_EULA=Y apt-get install -y \
    apt-transport-https \
    msodbcsql17

# Enable the php extensions.
RUN pecl install pdo_sqlsrv-5.6.1 sqlsrv-5.6.1 \
    && docker-php-ext-enable pdo_sqlsrv sqlsrv

CMD ["php-fpm", "-F"]
#end ODBC

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

RUN chown -R www-data:www-data /var/www

# Set working directory
WORKDIR /var/www/html

USER $user