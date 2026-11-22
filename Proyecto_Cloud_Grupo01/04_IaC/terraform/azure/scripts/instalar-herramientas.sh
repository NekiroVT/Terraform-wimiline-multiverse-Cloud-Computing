#!/bin/bash
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq ca-certificates curl unzip
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip -o "$work/aws.zip"
unzip -q "$work/aws.zip" -d "$work"
"$work/aws/install" --update
curl -fsSL https://aka.ms/downloadazcopy-v10-linux-arm64 -o "$work/azcopy.tar.gz"
tar -xzf "$work/azcopy.tar.gz" -C "$work"
install -m 0755 "$(find "$work" -type f -name azcopy | head -1)" /usr/local/bin/azcopy
install -d -m 0750 /opt/wimiline/bin
aws --version
azcopy --version
# PostgreSQL aislado para ensayar restauraciones; escucha localmente por defecto.
install -d -m 0755 /usr/share/postgresql-common/pgdg
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
printf 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt jammy-pgdg main\n' > /etc/apt/sources.list.d/pgdg.list
apt-get update -qq
apt-get install -y -qq postgresql-18 openjdk-21-jre-headless
