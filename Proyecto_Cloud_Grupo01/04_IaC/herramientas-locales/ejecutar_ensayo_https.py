from pathlib import Path
import subprocess, base64, json, os
root=Path(__file__).resolve().parent
az=root.parent/'terraform'/'azure'; private=root/'acme-privado'; tmp=private/'script-temporal-secreto.sh'
def cmd(args):
 p=subprocess.run(args,capture_output=True,text=True,check=True,timeout=40);return p.stdout.strip()
ip=cmd(['az.cmd','network','public-ip','show','-g','rg-wimiline-multicloud','-n','pip-ensayo-rto','--query','ipAddress','-o','tsv'])
url=cmd(['aws','s3','presign','s3://wimiline-deploy-339712696217-050f5bdf/releases/multiverso-release.zip','--region','us-east-1','--expires-in','1800'])
base=(az/'scripts/ensayo-recuperacion.sh').read_text(encoding='utf-8-sig').replace('__RELEASE_URL__',url).replace('__BACKUP_ID__','20261120T191712Z-ip-10-10-4-253').replace('__PUBLIC_IP__',ip)
base=base[base.index('curl -fsSL --retry 2 -o "$work/release.zip"'): ]
base='''#!/bin/bash
set -Eeuo pipefail
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
secret=$(openssl rand -hex 24)
runuser -u postgres -- psql -q -c "alter role rto_app password '$secret'" >/dev/null
'''+base
base=base.replace("if curl -fsS http://127.0.0.1/api/public/status >/dev/null 2>&1; then echo 'BACKEND_RESTAURADO_LISTO'; exit 0; fi", "if curl --noproxy '*' -fsS http://127.0.0.1/api/public/status >/dev/null 2>&1; then echo 'BACKEND_RESTAURADO_LISTO'; break; fi")
base=base.replace("echo 'BACKEND_NO_LISTO'; journalctl -u wimiline-rto -n 15 --no-pager | LC_ALL=C tr -cd '\\11\\12\\15\\40-\\176'; exit 1", "curl --noproxy '*' -fsS http://127.0.0.1/api/public/status >/dev/null")
tls=(az/'scripts/ensayo-https.sh').read_text(encoding='utf-8-sig')
for placeholder,filename in [('__CERT_CHAIN_BASE64__','ensayo-chain.pem'),('__PRIVATE_KEY_BASE64__','ensayo-key.pem')]: tls=tls.replace(placeholder,base64.b64encode((private/filename).read_bytes()).decode('ascii'))
tmp.write_text(base+'\n'+tls,encoding='utf-8',newline='\n')
print('IP_ENSAYO='+ip,flush=True)
try:
 p=subprocess.run(['az.cmd','vm','run-command','invoke','-g','rg-wimiline-multicloud','-n','vm-ensayo-rto','--command-id','RunShellScript','--scripts','@'+str(tmp),'--only-show-errors','-o','json'],capture_output=True,text=True,timeout=1200)
 if p.returncode: print('AZURE_COMMAND_ERROR',flush=True);raise SystemExit(p.returncode)
 d=json.loads(p.stdout); m='\n'.join(x.get('message','') for x in d.get('value',[]))
 for line in m.splitlines():
  if any(s in line for s in ('respaldo.dump: OK','BACKEND_RESTAURADO_LISTO','HTTPS_RESTAURACION_LISTO','HTTPS_BACKEND_NO_LISTO','nginx:','[stderr]')): print(line,flush=True)
 if 'HTTPS_RESTAURACION_LISTO' not in m: print('ERROR_NO_FINALIZO; revisar resultado privado en la VM temporal',flush=True); raise SystemExit(1)
finally:
 tmp.unlink(missing_ok=True)

