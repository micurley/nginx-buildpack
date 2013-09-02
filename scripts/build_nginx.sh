#!/bin/bash
#
# Requires 'vulcan' to be installed and a build server created.
# https://devcenter.heroku.com/articles/buildpack-binaries

NGINX_VERSION=1.5.2
PCRE_VERSION=8.21
HUK_VERSION=d7643c291ef0

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
#pcre_tarball_url=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.bz2
pcre_tarball_url=http://garr.dl.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
http_upstream_keepalive_url=http://mdounin.ru/hg/ngx_http_upstream_keepalive/archive/${HUK_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/vulcan_nginx.XXXXXXXXXX)

cleanup() {
  echo "Cleaning up $temp_dir"
  cd /
  rm -rf "$temp_dir"
}
trap cleanup EXIT

script_dir=$(cd $(dirname $0); pwd)
vulcan_archive_result=$temp_dir/nginx-${NGINX_VERSION}-built-with-vulcan.tar.gz
untarring_dir=$temp_dir/untarring
nginx_binary_drop_dir=$script_dir/../bin

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl $nginx_tarball_url | tar xf -

echo "Moving into ngninx directory"
cd nginx-${NGINX_VERSION}

echo "Downloading $pcre_tarball_url"
curl $pcre_tarball_url | tar xf -

echo "Downloading $http_upstream_keepalive_url"
curl $http_upstream_keepalive_url | tar xf -



vulcan build -o ${vulcan_archive_result} -s nginx-${NGINX_VERSION} -v -p /tmp/nginx -c \
    "./configure \
        --with-pcre=pcre-${PCRE_VERSION} \
        --add-module=ngx_http_upstream_keepalive-${HUK_VERSION} \
        --prefix=/tmp/nginx && \
        make install \
    "

echo "Extracting the nginx binary into the buildback"
mkdir -p $untarring_dir
cd $untarring_dir
tar -xf $vulcan_archive_result
mkdir -p $nginx_binary_drop_dir
cp sbin/nginx $nginx_binary_drop_dir

echo "Copied the nginx binary into $(cd $nginx_binary_drop_dir; pwd)"
