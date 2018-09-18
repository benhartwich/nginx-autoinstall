# nginx-autoinstall
Compile and install Nginx from source with optionnal modules.

![screenshot](https://user-images.githubusercontent.com/11699655/33800227-29565ef6-dd3c-11e7-9967-7232ecd36ee4.png)

## Compatibility

* x86, x64, arm*
* Debian 8 and later
* Ubuntu 16.04 and later

## Features

- Latest mainline or stable version, from source
- Optional modules (see below)
- Removed useless modules
- [Custom nginx.conf](https://github.com/benhartwich/nginx-autoinstall/blob/master/conf/nginx.conf) (default does not work)
- [Init script for systemd](https://github.com/benhartwich/nginx-autoinstall/blob/master/conf/nginx.service) (not provided by default)
- [Logrotate conf](https://github.com/benhartwich/nginx-autoinstall/blob/master/conf/nginx-logrotate) (not provided by default)
- Image filter module / empty_gif module for Matomo Analytics

### Optional modules/features

- [LibreSSL from source](http://www.libressl.org/) (ChaCha20 cipher, HTTP/2 + ALPN, Curve25519, P-521)
- [OpenSSL from source](https://www.openssl.org/) (ChaCha20 cipher, HTTP/2 + ALPN, Curve25519, P-521)
- [ngx_pagespeed](https://github.com/pagespeed/ngx_pagespeed) (Google performance module)
- [ngx_brotli](https://github.com/google/ngx_brotli) (Brotli compression algorithm)
- [ngx_headers_more](https://github.com/openresty/headers-more-nginx-module) (Custom HTTP headers)
- [GeoIP](http://dev.maxmind.com/geoip/geoip2/geolite2/) (GeoIP module and databases)
- [Mod Security](https://github.com/SpiderLabs/ModSecurity) (web application firewall)
- [OWASP Mod Security CSR](https://github.com/SpiderLabs/owasp-modsecurity-crs) (OWASP ModSecurity Core Rule Set)
- [Cloudflare's TLS Dynamic Records Resizing patch](https://github.com/cloudflare/sslconfig/blob/master/patches/nginx__1.11.5_dynamic_tls_records.patch) (Optmize lantency and throughput for TLS exchanges)
- [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge) (Purge content from FastCGI, proxy, SCGI and uWSGI caches)
- [ngx-fancyindex](https://github.com/aperezdc/ngx-fancyindex) (Fancy indexes module)

## Install Nginx

Just download and execute the script :
```
wget https://raw.githubusercontent.com/benhartwich/nginx-autoinstall/master/nginx-autoinstall.sh
chmod +x nginx-autoinstall.sh
./nginx-autoinstall.sh
```

## Uninstall Nginx

Just select the option when running the script :

![update](https://lut.im/Hj7wJKWwke/WZqeHT1QwwGfKXFf.png)

You have te choice to delete the logs and the conf.

## Update Nginx

To update Nginx, run the script and install Nginx again. It will overwrite current Nginx files and/or modules.

## Update the script

The update feature downloads the script from this repository, and overwrite the current `nginx-autoinstall.sh` file in the working directory. This allows you to get the latest features, bug fixes, and module versions automatically.

![update](https://lut.im/uQSSVxAz09/zhZRuvJjZp2paLHm.png)

## Log file

A log file is created when running the script. It is located at `/tmp/nginx-autoinstall.log`.

## LICENSE

GPL v3.0
