# nginx-static

A static build of nginx.

Includes njs, http3 support (from https://hg.nginx.org/nginx-quic), https://github.com/vozlt/nginx-module-vts, https://github.com/FRiCKLE/ngx_cache_purge.

There seems to be some problems with using nginx'es built in OCSP stapling with this build (and the built in does not work well with Must-Staple either way since it will not always staple) so instead I generate the OCSP response with `openssl ocsp -no_nonce -respout certs/ocsp.resp -issuer certs/ca.pem -cert certs/cert.pem -url $(openssl x509 -in certs/cert.pem -text | grep "OCSP - URI:" | cut -d: -f2,3)` and set it with `ssl_stapling_file`.
