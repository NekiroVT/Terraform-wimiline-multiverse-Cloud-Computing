#!/bin/bash
set -euo pipefail
exec > >(tee -a /var/log/multiverso-bootstrap.log | logger -t multiverso-bootstrap -s 2>/dev/console) 2>&1

export AWS_REGION=us-east-1
APP_DIR=/opt/multiverso
FRONT_DIR=/var/www/multiverso
BUNDLE=/tmp/multiverso-release.zip
DEPLOY_BUCKET=__BUCKET__
DEPLOY_KEY=releases/multiverso-release.zip

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl openjdk-21-jre-headless nginx unzip jq
curl --fail --silent --show-error --location 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' --output /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp/awscliv2
/tmp/awscliv2/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli
rm -rf /tmp/awscliv2 /tmp/awscliv2.zip
/usr/local/bin/aws --version
install -d -m 0755 "$APP_DIR/backend" "$FRONT_DIR"
useradd --system --home-dir "$APP_DIR" --shell /usr/sbin/nologin multiverso || true

aws s3 cp "s3://$DEPLOY_BUCKET/$DEPLOY_KEY" "$BUNDLE" --region "$AWS_REGION" --only-show-errors
# Preserve the exact release installed on this instance for cross-cloud recovery.
install -d -m 0700 /var/lib/wimiline-recovery
install -m 0600 "$BUNDLE" /var/lib/wimiline-recovery/multiverso-release.zip
unzip -q "$BUNDLE" -d /opt/multiverso-release
install -o root -g root -m 0644 /opt/multiverso-release/backend/app.jar "$APP_DIR/backend/app.jar"
cp -a /opt/multiverso-release/frontend/. "$FRONT_DIR/"
chown -R root:root "$APP_DIR" "$FRONT_DIR"
find "$APP_DIR" "$FRONT_DIR" -type d -exec chmod 0755 {} \;
find "$APP_DIR" "$FRONT_DIR" -type f -exec chmod 0644 {} \;
rm -rf /opt/multiverso-release "$BUNDLE"

cat >/etc/nginx/sites-available/multiverso <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/multiverso;
    index index.html;

    location ~ /\.(?!well-known) { deny all; }
    location = /api { return 301 /api/; }
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
        proxy_connect_timeout 5s;
        proxy_read_timeout 60s;
    }
    location = /runtime-config.js {
        add_header Cache-Control "no-store";
        try_files $uri =404;
    }
    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX
ln -sfn /etc/nginx/sites-available/multiverso /etc/nginx/sites-enabled/multiverso
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl restart nginx

cat >/usr/local/bin/multiverso-start <<'START'
#!/bin/bash
set -euo pipefail
export AWS_REGION=us-east-1
JWT_SECRET_BASE64="$(/usr/local/bin/aws ssm get-parameter --name /multiverso/prod/jwt-secret-base64 --with-decryption --query 'Parameter.Value' --output text --region "$AWS_REGION")"
DB_USERNAME=postgres
DB_PASSWORD="$(/usr/local/bin/aws ssm get-parameter --name /multiverso/prod/db-password --with-decryption --query 'Parameter.Value' --output text --region "$AWS_REGION")"
test -n "$JWT_SECRET_BASE64"
test -n "$DB_USERNAME"
test -n "$DB_PASSWORD"
export JWT_SECRET_BASE64 DB_USERNAME DB_PASSWORD
export DB_URL='jdbc:postgresql://__DB_ENDPOINT__:5432/multiverso'
export CORS_ALLOWED_ORIGINS='https://multiverso.wimiline.com'
export MULTIVERSO_REGISTRATION_QUEUE_URL='__QUEUE_URL__'
export SERVER_PORT=8080
exec /usr/bin/java -Xms96m -Xmx384m -XX:MaxMetaspaceSize=160m -XX:+UseSerialGC -XX:+ExitOnOutOfMemoryError -jar /opt/multiverso/backend/app.jar
START
chmod 0755 /usr/local/bin/multiverso-start

cat >/etc/systemd/system/multiverso.service <<'SERVICE'
[Unit]
Description=Multiverso Spring Boot API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=multiverso
Group=multiverso
WorkingDirectory=/opt/multiverso
ExecStart=/usr/local/bin/multiverso-start
Restart=on-failure
RestartSec=5
TimeoutStartSec=180
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true

[Install]
WantedBy=multi-user.target
SERVICE
systemctl daemon-reload
systemctl enable multiverso.service
systemctl start multiverso.service

# Cliente PostgreSQL de la misma versión principal que RDS, y respaldo lógico.
install -d -m 0755 /usr/share/postgresql-common/pgdg
curl --fail --silent --show-error https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
printf 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main\n' > /etc/apt/sources.list.d/pgdg.list
apt-get update -qq
apt-get install -y postgresql-client-18
cat > /usr/local/bin/wimiline-backup <<'BACKUP'
#!/bin/bash
set -Eeuo pipefail
umask 077
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
fail_backup() {
  logger -p user.err -t wimiline-backup 'Exportacion o copia a Azure fallida'
  aws cloudwatch put-metric-data --region us-east-1 --namespace Wimiline/Backup --metric-name CopyFailure --value 1 >/dev/null 2>&1 || true
}
trap fail_backup ERR
PGPASSWORD="$(aws ssm get-parameter --region us-east-1 --name /multiverso/prod/db-password --with-decryption --query Parameter.Value --output text)"
test -n "$PGPASSWORD"
export PGPASSWORD
backup_id="$(date -u +%Y%m%dT%H%M%SZ)-$(hostname)"
cd "$work"
pg_dump -h '__DB_ENDPOINT__' -U postgres -d multiverso -Fc -f respaldo.dump
sha256sum respaldo.dump > respaldo.dump.sha256
aws s3 cp respaldo.dump "s3://__BACKUP_BUCKET__/$backup_id/respaldo.dump" --region us-east-1 --only-show-errors
aws s3 cp respaldo.dump.sha256 "s3://__BACKUP_BUCKET__/$backup_id/respaldo.dump.sha256" --region us-east-1 --only-show-errors
if [[ "__PUSH_ENABLED__" == "true" ]]; then
  # Descargar desde S3 antes de enviar a Blob; la SAS queda solo en un archivo temporal root.
  aws s3 cp "s3://__BACKUP_BUCKET__/$backup_id/respaldo.dump" ./desde-s3.dump --region us-east-1 --only-show-errors
  cmp respaldo.dump desde-s3.dump
  container="$(aws ssm get-parameter --region us-east-1 --name /multiverso/prod/azure-blob-container-url --query Parameter.Value --output text)"
  sas="$(aws ssm get-parameter --region us-east-1 --name /multiverso/prod/azure-blob-sas --with-decryption --query Parameter.Value --output text)"
  [[ "${sas:0:1}" == "?" ]] || sas="?$sas"
  release_file=/var/lib/wimiline-recovery/multiverso-release.zip
  test -s "$release_file"
  release_hash="$(sha256sum "$release_file" | cut -d ' ' -f 1)"
  [[ "$release_hash" =~ ^[0-9a-f]{64}$ ]]
  printf '%s  multiverso-release.zip\n' "$release_hash" > release.sha256
  # The address is content-based; upload once per instance/container/release.
  marker_key="$(printf '%s/%s' "$container" "$release_hash" | sha256sum | cut -d ' ' -f 1)"
  marker="/var/lib/wimiline-recovery/uploaded-$marker_key"
  if [[ ! -f "$marker" ]]; then
    printf 'url = "%s/releases/%s/multiverso-release.zip%s"\nrequest = "PUT"\nupload-file = "%s"\nheader = "x-ms-blob-type: BlockBlob"\n' "$container" "$release_hash" "$sas" "$release_file" > curl-config
    chmod 600 curl-config
    curl --fail --silent --show-error --retry 2 --connect-timeout 15 --max-time 300 --config curl-config >/dev/null
    touch "$marker"
  fi
  for part in respaldo.dump respaldo.dump.sha256 release.sha256; do
    file="$part"; [[ "$part" == "respaldo.dump" ]] && file="desde-s3.dump"
    printf 'url = "%s/%s/%s%s"\nrequest = "PUT"\nupload-file = "%s"\nheader = "x-ms-blob-type: BlockBlob"\n' "$container" "$backup_id" "$part" "$sas" "$file" > curl-config
    chmod 600 curl-config
    curl --fail --silent --show-error --retry 2 --connect-timeout 15 --max-time 300 --config curl-config >/dev/null
  done
  rm -f curl-config
  unset sas
  aws cloudwatch put-metric-data --region us-east-1 --namespace Wimiline/Backup --metric-name CopySuccess --value 1
  logger -p user.notice -t wimiline-backup "Copia a Azure finalizada: $backup_id"
fi
logger -p user.notice -t wimiline-backup "Exportacion a S3 completa: $backup_id"
BACKUP
chmod 0700 /usr/local/bin/wimiline-backup
printf '15 */3 * * * root /usr/local/bin/wimiline-backup\n' > /etc/cron.d/wimiline-backup
