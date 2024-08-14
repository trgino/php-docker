# Use the official PHP image with Apache
FROM php:8.2-apache

# Install necessary extensions and tools
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libevent-dev \
    autoconf \
    pkg-config \
    zlib1g-dev \
    git \
    curl \
    wget \
    imagemagick \
    unzip \
    supervisor \
    openssl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd mbstring pdo pdo_mysql mysqli soap intl zip opcache \
    && docker-php-ext-install -j$(nproc) sockets \
    && docker-php-ext-install -j$(nproc) exif \
    && pecl install swoole \
    && pecl install imagick \
    && pecl install mongodb \
    && pecl install redis \
    && docker-php-ext-enable swoole imagick mongodb redis

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite, SSL, and vhost alias modules
RUN a2enmod rewrite ssl vhost_alias

# Set up the working directory
WORKDIR /var/www

# Copy configuration files from conf directory
COPY ./conf/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
COPY ./conf/apache-ssl.conf /etc/apache2/sites-available/default-ssl.conf
COPY ./conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./conf/redis.conf /etc/redis/redis.conf

# Create a self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/ssl-cert.key \
    -out /etc/ssl/certs/ssl-cert.crt \
    -subj "/C=US/ST=State/L=City/O=Company/OU=Org/CN=localhost"

# Copy the project files into the container
COPY ./projects /var/www/

# Set permissions for the project directory
RUN chown -R www-data:www-data /var/www/

# Expose ports for HTTP (80), HTTPS (443), MySQL (3306), MongoDB (27017), LavinMQ (15672, 5672), and Redis (6379)
EXPOSE 80 443 3306 27017 15672 5672 6379

# Start Supervisord to manage all services
CMD ["/usr/bin/supervisord"]
