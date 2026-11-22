#!/bin/bash
set -Eeuo pipefail
export DEBIAN_FRONTEND=noninteractive
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
apt-get update -qq
apt-get install -y -qq ca-certificates curl unzip nginx openjdk-21-jre-headless
install -d -m 0755 /usr/share/postgresql-common/pgdg
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
printf 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt jammy-pgdg main\n' >/etc/apt/sources.list.d/pgdg.list
apt-get update -qq
apt-get install -y -qq postgresql-18
curl -fsSL https://aka.ms/downloadazcopy-v10-linux-arm64 -o "$work/azcopy.tgz"
tar -xzf "$work/azcopy.tgz" -C "$work"
install -m 0755 "$(find "$work" -type f -name azcopy | head -1)" /usr/local/bin/azcopy
export AZCOPY_AUTO_LOGIN_TYPE=MSI
blob='https://wimilinebackupc84635de.blob.core.windows.net/respaldos/__BACKUP_ID__'
for attempt in $(seq 1 12); do
 if azcopy copy "$blob/respaldo.dump" "$work/respaldo.dump" --output-type=text >/dev/null 2>&1; then break; fi
 sleep 10
done
test -s "$work/respaldo.dump"
azcopy copy "$blob/respaldo.dump.sha256" "$work/respaldo.dump.sha256" --output-type=text >/dev/null
(cd "$work" && sha256sum -c respaldo.dump.sha256)
chmod 755 "$work"; chmod 644 "$work/respaldo.dump"
runuser -u postgres -- createdb multiverso
runuser -u postgres -- pg_restore --no-owner --no-privileges -d multiverso "$work/respaldo.dump"
secret=$(openssl rand -hex 24)
runuser -u postgres -- psql -q -c "create role rto_app login password '$secret'; grant connect on database multiverso to rto_app;" >/dev/null
runuser -u postgres -- psql -d multiverso -q -c "grant usage,create on schema public to rto_app; grant all privileges on all tables in schema public to rto_app; grant all privileges on all sequences in schema public to rto_app;" >/dev/null
# La versión de aplicación queda vinculada al respaldo y se recupera de Blob,
# sin depender de un enlace temporal ni de la disponibilidad de S3.
azcopy copy "$blob/release.sha256" "$work/release.sha256" --output-type=text >/dev/null
release_hash="$(cut -d ' ' -f1 "$work/release.sha256")"
[[ "$release_hash" =~ ^[0-9a-f]{64}$ ]]
container="${blob%/__BACKUP_ID__}"
azcopy copy "$container/releases/$release_hash/multiverso-release.zip" "$work/multiverso-release.zip" --output-type=text >/dev/null
(cd "$work" && sha256sum -c release.sha256)
unzip -q "$work/multiverso-release.zip" -d "$work/release"
install -d -m 0755 /opt/wimiline-rto /var/www/wimiline-rto /etc/wimiline-rto
install -m 0644 "$work/release/backend/app.jar" /opt/wimiline-rto/app.jar
cp -a "$work/release/frontend/." /var/www/wimiline-rto/
useradd --system --home-dir /opt/wimiline-rto --shell /usr/sbin/nologin rtoapp || true
jwt=$(openssl rand -base64 48 | tr -d '\n')
cat > /etc/wimiline-rto/app.env <<EOF
DB_URL=jdbc:postgresql://127.0.0.1:5432/multiverso
DB_USERNAME=rto_app
DB_PASSWORD=$secret
JWT_SECRET_BASE64=$jwt
SERVER_PORT=8080
CORS_ALLOWED_ORIGINS=http://__PUBLIC_IP__
EOF
chmod 600 /etc/wimiline-rto/app.env
cat >/etc/systemd/system/wimiline-rto.service <<'EOF'
[Unit]
Description=Aplicacion aislada de recuperacion Wimiline
After=network-online.target postgresql.service
[Service]
Type=simple
User=rtoapp
WorkingDirectory=/opt/wimiline-rto
EnvironmentFile=/etc/wimiline-rto/app.env
ExecStart=/usr/bin/java -Xms64m -Xmx160m -XX:MaxMetaspaceSize=128m -XX:+UseSerialGC -jar /opt/wimiline-rto/app.jar
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
EOF
cat >/etc/nginx/sites-available/wimiline-rto <<'EOF'
server {
 listen 80 default_server;
 server_name _;
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
ln -sfn /etc/nginx/sites-available/wimiline-rto /etc/nginx/sites-enabled/wimiline-rto
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl daemon-reload
systemctl enable --now wimiline-rto.service nginx
systemctl reload nginx
for i in $(seq 1 180); do
 if curl -fsS http://127.0.0.1/api/public/status >/dev/null 2>&1; then echo 'BACKEND_RESTAURADO_LISTO'; exit 0; fi
 sleep 1
done
echo 'BACKEND_NO_LISTO'; journalctl -u wimiline-rto -n 15 --no-pager | LC_ALL=C tr -cd '\11\12\15\40-\176'; exit 1
