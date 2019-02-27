#!/bin/bash

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "Sorry, you need to run this as root"
	exit 1
fi

# Variables
NGINX_MAINLINE_VER=1.15.9
NGINX_STABLE_VER=1.14.2
LIBRESSL_VER=2.7.5
OPENSSL_VER=1.1.1
NPS_VER=1.13.35.2
HEADERMOD_VER=0.33
LIBMAXMINDDB_VER=1.3.2
GEOIP2_VER=3.2
OWASP_VER=3.1.0

clear
echo ""
echo "Welcome to the nginx-autoinstall script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update Nginx"
echo "   2) Uninstall Nginx"
echo "   3) Update the script"
echo "   4) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" ]]; do
	read -p "Select an option [1-4]: " OPTION
done
case $OPTION in
	1)
		echo ""
		echo "This script will install Nginx with some optional modules."
		echo ""
		echo "Do you want to install Nginx stable or mainline?"
		echo "   1) Stable $NGINX_STABLE_VER"
		echo "   2) Mainline $NGINX_MAINLINE_VER"
		echo ""
		while [[ $NGINX_VER != "1" && $NGINX_VER != "2" ]]; do
			read -p "Select an option [1-2]: " NGINX_VER
		done
		case $NGINX_VER in
			1)
			NGINX_VER=$NGINX_STABLE_VER
			;;
			2)
			NGINX_VER=$NGINX_MAINLINE_VER
			;;
		esac
		echo ""
		echo "Please tell me which modules you want to install."
		echo "If you select none, Nginx will be installed with its default modules."
		echo ""
		echo "Modules to install :"
		while [[ $PAGESPEED != "y" && $PAGESPEED != "n" ]]; do
			read -p "       PageSpeed $NPS_VER [y/n]: " -e PAGESPEED
		done
		while [[ $BROTLI != "y" && $BROTLI != "n" ]]; do
			read -p "       Brotli [y/n]: " -e BROTLI
		done
		while [[ $HEADERMOD != "y" && $HEADERMOD != "n" ]]; do
			read -p "       Headers More $HEADERMOD_VER [y/n]: " -e HEADERMOD
		done
		while [[ $GEOIP != "y" && $GEOIP != "n" ]]; do
			read -p "       GeoIP [y/n]: " -e GEOIP
		done
		while [[ $MODSECURE != "y" && $MODSECURE != "n" ]]; do
			read -p "       Mod Security + OWASP $OWASP_VER [y/n]: " -e MODSECURE
		done
		while [[ $FANCYINDEX != "y" && $FANCYINDEX != "n" ]]; do
			read -p "       Fancy index [y/n]: " -e FANCYINDEX
		done
		while [[ $CACHEPURGE != "y" && $CACHEPURGE != "n" ]]; do
			read -p "       ngx_cache_purge [y/n]: " -e CACHEPURGE
		done
		echo ""
		echo "Choose your OpenSSL implementation :"
		echo "   1) System's OpenSSL ($(openssl version | cut -c9-14))"
		echo "   2) OpenSSL $OPENSSL_VER from source"
		echo "   3) LibreSSL $LIBRESSL_VER from source "
		echo ""
		while [[ $SSL != "1" && $SSL != "2" && $SSL != "3" ]]; do
			read -p "Select an option [1-3]: " SSL
		done
		case $SSL in
			2)
				OPENSSL=y
			;;
			3)
				LIBRESSL=y
			;;
		esac
		echo ""
		read -n1 -r -p "Nginx is ready to be installed, press any key to continue..."
		echo ""

		# Cleanup
		# The directory should be deleted at the end of the script, but in case it fails
		rm -r /usr/local/src/nginx/ >> /dev/null 2>&1
		mkdir -p /usr/local/src/nginx/modules

		# Dependencies
		apt-get update
		apt-get install -y build-essential ca-certificates wget curl libpcre3 libpcre3-dev autoconf unzip automake libtool tar git libssl-dev zlib1g-dev uuid-dev lsb-release

		# PageSpeed
		if [[ "$PAGESPEED" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VER}-stable.zip
			unzip v${NPS_VER}-stable.zip
			cd incubator-pagespeed-ngx-${NPS_VER}-stable || exit 1
			psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_VER}.tar.gz
			[ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL)
			wget "${psol_url}"
			tar -xzvf "$(basename "${psol_url}")"
		fi

		#Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			git clone https://github.com/eustas/ngx_brotli
			cd ngx_brotli || exit 1
			git checkout v0.1.2
			git submodule update --init
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz
			tar xaf v${HEADERMOD_VER}.tar.gz
		fi

		# GeoIP
		if [[ "$GEOIP" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			# install libmaxminddb
			wget https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VER}/libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz
			tar xaf libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz
			cd libmaxminddb-${LIBMAXMINDDB_VER}/
			./configure
			make
			make install
			ldconfig

			cd ../
			wget https://github.com/leev/ngx_http_geoip2_module/archive/${GEOIP2_VER}.tar.gz
			tar xaf ${GEOIP2_VER}.tar.gz

			mkdir geoip-db
			cd geoip-db || exit 1
			wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz
			wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
			tar -xf GeoLite2-City.tar.gz
			tar -xf GeoLite2-Country.tar.gz
			mkdir /opt/geoip
			cd GeoLite2-City_*/
			mv GeoLite2-City.mmdb /opt/geoip/
			cd ../
			cd GeoLite2-Country_*/
			mv GeoLite2-Country.mmdb /opt/geoip/
		fi

		# Mod Security
		if [[ "$MODSECURE" = 'y' ]]; then
			# Dependence
			apt-get install apt-utils autoconf automake build-essential git libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre++-dev libtool libxml2-dev libyajl-dev pkgconf wget zlib1g-dev -y 
			cd /usr/local/src/nginx/modules || exit 1
			mkdir mod-security
			cd mod-security || exit 1
			git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity 

			cd ModSecurity || exit 1
			git submodule init 
			git submodule update 
			./build.sh 
			./configure 

			make -j $(nproc) 

			# Mod Security install
			make install 

			# Mod Security Connector
			cd /usr/local/src/nginx/modules
			mkdir mod-security-nginx
			cd mod-security-nginx || exit 1
			git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git 

			# Mod Security OWASP
			cd /usr/local/src/nginx/modules || exit 1
			wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v${OWASP_VER}.tar.gz  
			tar -xzvf v${OWASP_VER}.tar.gz 
			mv owasp-modsecurity-crs-${OWASP_VER} owasp-modsecurity-crs 
			if [ -d "/usr/local/owasp-modsecurity-crs" ]; then
				rm -R /usr/local/owasp-modsecurity-crs  
			fi
			mv owasp-modsecurity-crs /usr/local/
			cd /usr/local/owasp-modsecurity-crs 
			cp crs-setup.conf.example crs-setup.conf 
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			git clone https://github.com/FRiCKLE/ngx_cache_purge
		fi

		# LibreSSL
		if [[ "$LIBRESSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			mkdir libressl-${LIBRESSL_VER}
			cd libressl-${LIBRESSL_VER} || exit 1
			wget -qO- http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz | tar xz --strip 1

			./configure \
				LDFLAGS=-lrt \
				CFLAGS=-fstack-protector-strong \
				--prefix=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER}/.openssl/ \
				--enable-shared=no

			make install-strip -j "$(nproc)"
		fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz
			tar xaf openssl-${OPENSSL_VER}.tar.gz
			cd openssl-${OPENSSL_VER}

			./config
		fi

		# Download and extract of Nginx source code
		cd /usr/local/src/nginx/ || exit 1
		wget -qO- http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf -
		cd nginx-${NGINX_VER}

		# As the default nginx.conf does not work
		# We download a clean and working conf from my GitHub.
		# We do it only if it does not already exist (in case of update for instance)
		if [[ ! -e /etc/nginx/nginx.conf ]]; then
			mkdir -p /etc/nginx
			cd /etc/nginx || exit 1
			wget https://raw.githubusercontent.com/benhartwich/nginx-autoinstall/master/conf/nginx.conf 
		fi
		cd /usr/local/src/nginx/nginx-${NGINX_VER}

		# Modules configuration
		# Common configuration
		NGINX_OPTIONS="
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--user=nginx \
		--group=nginx \
		--with-cc-opt=-Wno-deprecated-declarations"


		NGINX_MODULES="--with-threads \
		--with-file-aio \
		--with-http_ssl_module \
		--with-http_v2_module \
		--with-http_mp4_module \
		--with-http_auth_request_module \
		--with-http_slice_module \
		--with-http_stub_status_module \
		--with-http_realip_module \
		--with-http_image_filter_module"

		# Optional modules
		# LibreSSL
		if [[ "$LIBRESSL" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo --with-openssl=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER})
		fi

		# PageSpeed
		if [[ "$PAGESPEED" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/incubator-pagespeed-ngx-${NPS_VER}-stable")
		fi

		# Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_brotli")
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/headers-more-nginx-module-${HEADERMOD_VER}")
		fi

		# GeoIP
		if [[ "$GEOIP" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_http_geoip2_module-${GEOIP2_VER}")
		fi

		# Mod Security
		if [[ "$MODSECURE" = 'y' ]]; then
			mkdir /etc/nginx/modsec
			wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended 
			mv /etc/nginx/modsec/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf 
			wget -P /etc/nginx/modsec/ https://raw.githubusercontent.com/benhartwich/nginx-autoinstall/master/conf/firewall.conf 
			sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf 
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/mod-security-nginx/ModSecurity-nginx/")
		fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-openssl=/usr/local/src/nginx/modules/openssl-${OPENSSL_VER}")
		fi
		
		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_cache_purge")
		fi

		# Fancy index
		if [[ "$FANCYINDEX" = 'y' ]]; then
			git clone --quiet https://github.com/aperezdc/ngx-fancyindex.git /usr/local/src/nginx/modules/fancyindex
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo --add-module=/usr/local/src/nginx/modules/fancyindex)
		fi

		# We configure Nginx
		./configure $NGINX_OPTIONS $NGINX_MODULES
		make -j "$(nproc)"
		make install

		# remove debugging symbols
		strip -s /usr/sbin/nginx

		# Nginx installation from source does not add an init script for systemd and logrotate
		# Using the official systemd script and logrotate conf from nginx.org
		if [[ ! -e /lib/systemd/system/nginx.service ]]; then
			cd /lib/systemd/system/ || exit 1
			wget https://raw.githubusercontent.com/benhartwich/nginx-autoinstall/master/conf/nginx.service 
			# Enable nginx start at boot
			systemctl enable nginx 
		fi

		if [[ ! -e /etc/logrotate.d/nginx ]]; then
			cd /etc/logrotate.d/ || exit 1
			wget https://raw.githubusercontent.com/benhartwich/nginx-autoinstall/master/conf/nginx-logrotate -O nginx 
		fi

		# Nginx's cache directory is not created by default
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# We add the sites-* folders as some use them. 
		if [[ ! -d /etc/nginx/sites-available ]]; then
			mkdir -p /etc/nginx/sites-available
		fi
		if [[ ! -d /etc/nginx/sites-enabled ]]; then
			mkdir -p /etc/nginx/sites-enabled
		fi

		# Restart Nginx
		systemctl restart nginx 
		

		# Block Nginx from being installed via APT
		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			cd /etc/apt/preferences.d/ || exit 1
			echo -e "Package: nginx*\\nPin: release *\\nPin-Priority: -1" > nginx-block
		fi

		# Removing temporary Nginx and modules files
		rm -r /usr/local/src/nginx

		# We're done !
		echo "Installation done."
	exit
	;;
	2) # Uninstall Nginx
		while [[ $CONF !=  "y" && $CONF != "n" ]]; do
			read -p "       Remove configuration files ? [y/n]: " -e CONF
		done
		while [[ $LOGS !=  "y" && $LOGS != "n" ]]; do
			read -p "       Remove logs files ? [y/n]: " -e LOGS
		done
		# Stop Nginx
		systemctl stop nginx

		# Removing Nginx files and modules files
		rm -r /usr/local/src/nginx \
		/usr/sbin/nginx* \
		/etc/logrotate.d/nginx \
		/var/cache/nginx \
		/lib/systemd/system/nginx.service \
		/etc/systemd/system/multi-user.target.wants/nginx.service

		# Remove conf files
		if [[ "$CONF" = 'y' ]]; then
			rm -r /etc/nginx/ 
		fi

		# Remove logs
		if [[ "$LOGS" = 'y' ]]; then
			rm -r /var/log/nginx
		fi

		# Remove Nginx APT block
		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			rm /etc/apt/preferences.d/nginx-block
		fi

		# We're done !
		echo "Uninstallation done."
		
		
	exit
	;;
	3) # Update the script
		wget https://raw.githubusercontent.com/benhartwich/nginx-autoinstall/master/nginx-autoinstall.sh -O nginx-autoinstall.sh
		chmod +x nginx-autoinstall.sh
		echo ""
		echo "Update done."
		sleep 2
		./nginx-autoinstall.sh
		exit
	;;
	4) # Exit
		exit
	;;

esac
