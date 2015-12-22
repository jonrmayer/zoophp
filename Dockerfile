# PHP
# Ubuntu 14.04

# CREDITS: Based on http://www.peterstratton.com/2014/04/how-to-install-postgis-2-dot-1-and-postgresql-9-dot-3-on-ubuntu-servers/

FROM ubuntu:14.04

MAINTAINER Jonathan Mayer jonathan.mayer@ecountability.co.uk

# Update the Ubuntu repository indexes -----------------------------------------------------------------#
RUN apt-get update && apt-get upgrade -y

# Install dependencies Step 1  ------------------------------------------------------------------------------------------------#
RUN apt-get install build-essential
   
# Install dependencies Step 2  ------------------------------------------------------------------------------------------------#
RUN apt-get install openssl libssl-dev openssl-blacklist openssl-blacklist-extra  bison autoconf automake libtool re2c flex apache-prefork-dev
   
# Install dependencies Step 3  ------------------------------------------------------------------------------------------------#
RUN apt-get install libxml2-dev libssl-dev libbz2-dev libcurl3-dev libdb5.1-dev libjpeg-dev libpng-dev libXpm-dev libfreetype6-dev libt1-dev libgmp3-dev libc-client-dev libldap2-dev libmcrypt-dev libmhash-dev freetds-dev libz-dev libmysqlclient15-dev ncurses-dev libpcre3-dev unixODBC-dev postgresql-server-dev-9.1 libsqlite-dev libaspell-dev libreadline6-dev librecode-dev libsnmp-dev libtidy-dev libxslt-dev libt1-dev


# Install PostgreSQL libraries ----------------------------------------------------------------------------------------#
RUN apt-get install -y postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3 libpq-dev postgresql-server-dev-9.3

# Build GDAL and GEOS from source -------------------------------------------------------------------------------------#
ENV PROCESSORS 4

RUN cd /usr/local/src && \
    wget http://download.osgeo.org/gdal/1.11.1/gdal-1.11.1.tar.gz && \
    tar xfz gdal-1.11.1.tar.gz && \
    wget http://download.osgeo.org/geos/geos-3.4.2.tar.bz2 && \
    bunzip2 geos-3.4.2.tar.bz2 && \
    tar xvf geos-3.4.2.tar && \
    rm geos-3.4.2.tar && \
    rm gdal-1.11.1.tar.gz && \
    cd /usr/local/src/geos-3.4.2 && \
    ./configure && make -j$PROCESSORS && make install && ldconfig && \
    cd /usr/local/src/gdal-1.11.1 && \
    rm -rf /usr/local/src/geos-3.4.2 && \
    ./configure --with-python && \
    make -j$PROCESSORS && make install && ldconfig && \
    apt-get install -y python-gdal && \
    cd /usr/local/src && \
    rm -rf /usr/local/src/gdal-1.11.1

# Install PostGIS -----------------------------------------------------------------------------------------------------#
RUN apt-get -y -q install postgresql-9.3-postgis-2.1

# Variables -----------------------------------------------------------------------------------------------------------#
ENV POSTGIS_GDAL_ENABLED_DRIVERS ENABLE_ALL
ENV POSTGIS_ENABLE_OUTDB_RASTERS 1

# Modify config files -------------------------------------------------------------------------------------------------#
# Allow remote connections to the database and listen to all addresses
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

# Setup supervisor ----------------------------------------------------------------------------------------------------#
RUN mkdir -p /var/log/supervisor && \
    locale-gen en_US en_US.UTF-8
ADD supervisord.conf /etc/supervisor/conf.d/

# Add startup script --------------------------------------------------------------------------------------------------#
COPY startup.sh /usr/local/bin/startup.sh
RUN chmod +x /usr/local/bin/startup.sh

# Expose the PostgreSQL port ------------------------------------------------------------------------------------------#
EXPOSE 5432

# Add VOLUMEs to for inspection, datastorage, and backup --------------------------------------------------------------#
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql", "/var/lib/ckan/default", "/var/log/supervisor"]

CMD ["/usr/local/bin/startup.sh"]
