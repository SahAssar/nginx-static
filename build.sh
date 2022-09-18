#!/usr/bin/env bash

apt install -y build-essential

dest="/tmp/nginx-build-http3"
rm -rf "$dest"
mkdir -p "$dest"
set -euo pipefail
currdir="$(pwd)"
builddir="$(mktemp -d)"
cd "${builddir}"
git clone https://github.com/nginx/njs.git --branch="$NJS_VERSION" --recurse-submodules
git clone https://github.com/google/ngx_brotli.git --recurse-submodules && (cd ngx_brotli && git reset --hard "$NGX_BROTLI_COMMIT" && git submodule foreach --recursive git reset --hard)
git clone https://github.com/quictls/openssl.git --branch="$OPENSSL_VERSION" --recurse-submodules
git clone https://github.com/openresty/headers-more-nginx-module.git --branch="$HEADERS_MORE_NGINX_MODULE_VERSION" --recurse-submodules
git clone https://github.com/vozlt/nginx-module-vts.git --recurse-submodules && (cd nginx-module-vts && git reset --hard "$NGINX_MODULE_VTS_COMMIT" && git submodule foreach --recursive git reset --hard)
git clone https://github.com/FRiCKLE/ngx_cache_purge.git --branch="$NGX_CACHE_PURGE_VERSION" --recurse-submodules
hg clone -b quic https://hg.nginx.org/nginx-quic
cd nginx-quic
# TODO: Fix mercurial clone version, right now it seems like all the tags on the nginx-quic repo point to non-quic versions
# hg update -r "$NGINX_VERSION"
# -Wno-vla-parameter is needed on arch linux, see https://github.com/google/ngx_brotli/issues/121
# -Wno-stringop-overread is needed for nginx-module-vts, see https://github.com/vozlt/nginx-module-vts/issues/223
./auto/configure \
  --prefix="$dest" \
  --with-cc-opt="-I../openssl/build/include -Wno-stringop-overread -Wno-vla-parameter -O2" \
  --with-ld-opt="-L../openssl/build/lib -static -static-libgcc" \
  --error-log-path="/dev/null" \
  --pid-path="/dev/null" \
  --with-cpu-opt=generic \
  --with-threads \
  --with-file-aio \
  --with-poll_module \
  --with-select_module \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_gzip_static_module \
  --with-http_auth_request_module \
  --with-http_v3_module \
  --without-http_ssi_module \
  --without-http_userid_module \
  --without-http_auth_basic_module \
  --without-http_mirror_module \
  --without-http_autoindex_module \
  --without-http_uwsgi_module \
  --without-http_fastcgi_module \
  --without-http_scgi_module \
  --without-http_grpc_module \
  --without-http_memcached_module \
  --without-mail_pop3_module \
  --without-mail_imap_module \
  --without-mail_smtp_module \
  --without-stream_limit_conn_module \
  --without-stream_access_module \
  --without-stream_geo_module \
  --without-stream_map_module \
  --without-stream_split_clients_module \
  --without-stream_return_module \
  --without-stream_set_module \
  --without-stream_upstream_hash_module \
  --without-http_browser_module \
  --without-stream_upstream_least_conn_module \
  --without-stream_upstream_random_module \
  --without-stream_upstream_zone_module \
  --add-module=../njs/nginx \
  --add-module=../ngx_brotli \
  --add-module=../headers-more-nginx-module \
  --add-module=../nginx-module-vts \
  --add-module=../ngx_cache_purge \
  --with-openssl=../openssl \
  --with-pcre-jit
make -j1
make install
cd "$currdir"
chmod +x $dest/sbin/nginx
chmod +r $dest/sbin/nginx
chmod -w $dest/sbin/nginx
mv -f "$dest/sbin/nginx" /tmp/nginx-http3
gzip /tmp/nginx-http3
# sudo setcap 'cap_net_bind_service=+ep' ./nginx-http3
# sudo chown root:root ./nginx-http3
