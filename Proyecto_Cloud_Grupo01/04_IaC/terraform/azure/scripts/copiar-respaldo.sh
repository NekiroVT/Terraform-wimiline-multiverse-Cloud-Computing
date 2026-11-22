#!/usr/bin/env bash
# Copia un respaldo lógico y su manifiesto: configure las variables mediante un mecanismo seguro.
set -Eeuo pipefail
: "${WIMILINE_S3_OBJECT:?Configure la URI s3:// del respaldo}"
: "${WIMILINE_S3_MANIFEST:?Configure la URI s3:// del manifiesto SHA-256}"
: "${WIMILINE_AZURE_CONTAINER:?Configure la URL HTTPS del contenedor Blob}"
: "${WIMILINE_BACKUP_ID:?Configure un identificador único para cada copia}"
[[ "$WIMILINE_BACKUP_ID" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "ID de respaldo no válido" >&2; exit 1; }
work=$(mktemp -d)
cleanup(){ rm -rf "$work"; }
fail(){ logger -p user.err -t wimiline-backup 'Transferencia fallida; revisar configuración y credenciales.'; }
trap cleanup EXIT
trap fail ERR
export AZCOPY_AUTO_LOGIN_TYPE=MSI
cd "$work"
aws s3 cp "$WIMILINE_S3_OBJECT" ./respaldo.dump --only-show-errors
aws s3 cp "$WIMILINE_S3_MANIFEST" ./respaldo.dump.sha256 --only-show-errors
# El manifiesto debe contener el hash seguido del nombre respaldo.dump.
sha256sum -c respaldo.dump.sha256
azcopy copy respaldo.dump "$WIMILINE_AZURE_CONTAINER/$WIMILINE_BACKUP_ID/respaldo.dump" --overwrite=false
azcopy copy respaldo.dump.sha256 "$WIMILINE_AZURE_CONTAINER/$WIMILINE_BACKUP_ID/respaldo.dump.sha256" --overwrite=false
mkdir verificacion
azcopy copy "$WIMILINE_AZURE_CONTAINER/$WIMILINE_BACKUP_ID/respaldo.dump" verificacion/respaldo.dump
cmp respaldo.dump verificacion/respaldo.dump
logger -p user.notice -t wimiline-backup 'Copia enviada e integridad del destino verificada.'