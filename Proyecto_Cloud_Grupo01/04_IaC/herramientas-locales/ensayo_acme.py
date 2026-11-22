from pathlib import Path
from datetime import datetime, timedelta, timezone
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from acme import client, messages, challenges
import josepy as jose
import requests, sys
root=Path(__file__).parent/'acme-privado'; root.mkdir(exist_ok=True)
account=rsa.generate_private_key(public_exponent=65537,key_size=2048)
account_key=jose.JWKRSA(key=account)
net=client.ClientNetwork(account_key,user_agent='wimiline-recovery-test/1.0')
directory=messages.Directory.from_json(requests.get('https://acme-v02.api.letsencrypt.org/directory',timeout=20).json())
c=client.ClientV2(directory,net)
net.account=c.new_account(messages.NewRegistration.from_data(terms_of_service_agreed=True))
key=rsa.generate_private_key(public_exponent=65537,key_size=2048)
name=x509.Name([x509.NameAttribute(NameOID.COMMON_NAME,'multiverso.wimiline.com')])
csr=x509.CertificateSigningRequestBuilder().subject_name(name).add_extension(x509.SubjectAlternativeName([x509.DNSName('multiverso.wimiline.com')]),critical=False).sign(key,hashes.SHA256())
order=c.new_order(csr.public_bytes(serialization.Encoding.PEM))
auth=order.authorizations[0]
challenge=next(x for x in auth.body.challenges if isinstance(x.chall,challenges.DNS01))
print('DNS_TXT_NAME=_acme-challenge.multiverso.wimiline.com',flush=True)
print('DNS_TXT_VALUE='+challenge.chall.validation(account_key),flush=True)
print('ESPERANDO_CONFIRMACION',flush=True)
if sys.stdin.readline().strip()!='continuar': raise SystemExit('Cancelado')
c.answer_challenge(challenge,challenge.response(account_key))
order=c.poll_and_finalize(order,deadline=datetime.now()+timedelta(minutes=8))
(root/'ensayo-key.pem').write_bytes(key.private_bytes(serialization.Encoding.PEM,serialization.PrivateFormat.PKCS8,serialization.NoEncryption()))
(root/'ensayo-chain.pem').write_text(order.fullchain_pem,encoding='ascii')
print('CERTIFICADO_EMITIDO',flush=True)

