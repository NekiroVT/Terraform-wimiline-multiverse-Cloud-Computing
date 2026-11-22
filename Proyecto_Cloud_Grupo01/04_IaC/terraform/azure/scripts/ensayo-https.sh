#!/bin/bash
set -Eeuo pipefail
umask 077
install -d -m 0700 /etc/wimiline-rto/tls
printf '%s' '__CERT_CHAIN_BASE64__' | base64 -d > /etc/wimiline-rto/tls/fullchain.pem
printf '%s' '__PRIVATE_KEY_BASE64__' | base64 -d > /etc/wimiline-rto/tls/privkey.pem
openssl x509 -in /etc/wimiline-rto/tls/fullchain.pem -noout -checkend 3600 >/dev/null
openssl pkey -in /etc/wimiline-rto/tls/privkey.pem -noout >/dev/null
sed -i 's|^CORS_ALLOWED_ORIGINS=.*|CORS_ALLOWED_ORIGINS=https://multiverso.wimiline.com|' /etc/wimiline-rto/app.env
cat >/etc/nginx/sites-available/wimiline-rto <<'EOF'
server {
 listen 80 default_server;
 server_name multiverso.wimiline.com;
 return 301 https://$host$request_uri;
}
server {
 listen 443 ssl default_server;
 server_name multiverso.wimiline.com;
 ssl_certificate /etc/wimiline-rto/tls/fullchain.pem;
 ssl_certificate_key /etc/wimiline-rto/tls/privkey.pem;
 ssl_protocols TLSv1.2 TLSv1.3;
 root /var/www/wimiline-rto;
 index index.html;
 location /api/ {
  proxy_pass http://127.0.0.1:8080;
  proxy_set_header Host $host;
  proxy_set_header X-Forwarded-Proto $scheme;
 }
 location / { try_files $uri $uri/ /index.html; }
}
EOF
nginx -t
systemctl restart wimiline-rto.service
systemctl reload nginx
for i in $(seq 1 180); do
 if curl --noproxy '*' --resolve multiverso.wimiline.com:443:127.0.0.1 -fsS https://multiverso.wimiline.com/api/public/status >/dev/null 2>&1; then echo HTTPS_RESTAURACION_LISTO; exit 0; fi
 sleep 1
done
echo HTTPS_BACKEND_NO_LISTO
exit 1
