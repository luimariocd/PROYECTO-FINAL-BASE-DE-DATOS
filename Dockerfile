FROM php:8.3-cli

# Esta parte del código se encarga de instalar dependencias necesarias y herramientas para Oracle Instant Client. necesarias y herramientas para Oracle Instant Client
RUN apt-get update && apt-get install -y \
    libaio1t64 \
    unzip \
    wget \
    && ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1 \
    && rm -rf /var/lib/apt/lists/*

# Descargar e instalar Oracle Instant Client Basic & SDK
WORKDIR /opt/oracle
RUN wget -q https://download.oracle.com/otn_software/linux/instantclient/2350000/instantclient-basic-linux.x64-23.5.0.24.07.zip \
    && wget -q https://download.oracle.com/otn_software/linux/instantclient/2350000/instantclient-sdk-linux.x64-23.5.0.24.07.zip \
    && unzip -qo instantclient-basic-linux.x64-23.5.0.24.07.zip \
    && unzip -qo instantclient-sdk-linux.x64-23.5.0.24.07.zip \
    && rm -f *.zip \
    && echo /opt/oracle/instantclient_23_5 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Compilar y habilitar la extensión OCI8 en PHP
RUN echo "instantclient,/opt/oracle/instantclient_23_5" | pecl install oci8 \
    && docker-php-ext-enable oci8

WORKDIR /var/www/html
EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "app/public"]