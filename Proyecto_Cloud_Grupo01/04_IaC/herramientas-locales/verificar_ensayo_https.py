import socket,ssl,http.client,time,json,datetime,pathlib,secrets
ip='172.202.197.53'; host='multiverso.wimiline.com'; path=pathlib.Path(r'D:\CódigosNK-Poyectos\Cloud computing Entregables\Entregable 3 Final\06_Pruebas\rto-https-temporal.json')
ctx=ssl.create_default_context()
def req(endpoint, body=None):
 raw=socket.create_connection((ip,443),timeout=5)
 with ctx.wrap_socket(raw,server_hostname=host) as s:
  data=json.dumps(body).encode() if body else b''; method='POST' if body else 'GET'
  s.sendall((f'{method} {endpoint} HTTP/1.1\r\nHost: {host}\r\nConnection: close\r\nContent-Type: application/json\r\nContent-Length: {len(data)}\r\n\r\n').encode()+data)
  resp=http.client.HTTPResponse(s);resp.begin();resp.read();return resp.status
for i in range(180):
 try:
  web=req('/');api=req('/api/public/status')
  if web==200 and api==200:
   now=datetime.datetime.now(datetime.timezone.utc);d=json.loads(path.read_text(encoding='utf-8'));d.update({'primera_respuesta_utc':now.isoformat(),'web_https':web,'api_https':api,'tls_certificado':'verificado contra CA pública y nombre multiverso.wimiline.com','segundos_hasta_web_api':round((now-datetime.datetime.fromisoformat(d['inicio_utc'])).total_seconds(),1)})
   email='rto-https-'+secrets.token_hex(5)+'@example.invalid';pw=secrets.token_urlsafe(18)
   d['registro_https']=req('/api/auth/register',{'displayName':'Ensayo HTTPS','email':email,'password':pw});d['login_https']=req('/api/auth/login',{'email':email,'password':pw});done=datetime.datetime.now(datetime.timezone.utc)
   d['validacion_funcional_utc']=done.isoformat();d['segundos_hasta_login']=round((done-datetime.datetime.fromisoformat(d['inicio_utc'])).total_seconds(),1);d['ip_de_prueba']=ip
   path.write_text(json.dumps(d,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(d,ensure_ascii=False),flush=True);break
 except Exception: pass
 time.sleep(5)
else: print('TIEMPO_AGOTADO',flush=True)
