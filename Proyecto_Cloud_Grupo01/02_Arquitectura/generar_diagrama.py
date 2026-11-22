from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
matplotlib.rcParams['svg.fonttype']='none'
r=Path(__file__).resolve().parent
fig,ax=plt.subplots(figsize=(16,10),dpi=150);fig.patch.set_facecolor('#f4f7fa');ax.set_facecolor('#f4f7fa');ax.set_xlim(0,16);ax.set_ylim(0,10);ax.axis('off')
def rect(x,y,w,h,title,lines,color='#1c6584'):
 ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle='round,pad=0.04,rounding_size=0.12',linewidth=1.35,edgecolor=color,facecolor='white'))
 ax.text(x+.16,y+h-.14,title,fontsize=13,fontweight='bold',color=color,va='top')
 for i,line in enumerate(lines):ax.text(x+.16,y+h-.43-i*.23,line,fontsize=10,color='#253a50',va='top')
def arrow(p,q,color='#536d85',style='-|>',connection='arc3'):
 ax.add_patch(FancyArrowPatch(p,q,arrowstyle=style,mutation_scale=13,linewidth=1.8,color=color,connectionstyle=connection))
ax.text(.35,9.7,'WIMILINE · Arquitectura multicloud implementada',fontsize=22,fontweight='bold',color='#102e4c',va='top')
ax.text(.37,9.35,'AWS + Azure · Respaldo de datos y paquete de aplicación · 20/11/2026',fontsize=11,color='#52667a',va='top')
ax.add_patch(FancyBboxPatch((.25,1.4),9.0,7.65,boxstyle='round,pad=0.04,rounding_size=0.2',linewidth=1.5,edgecolor='#d78b24',facecolor='#fffaf1'))
ax.add_patch(FancyBboxPatch((9.55,1.4),6.15,7.65,boxstyle='round,pad=0.04,rounding_size=0.2',linewidth=1.5,edgecolor='#2185b0',facecolor='#f0f8fd'))
ax.text(.45,8.85,'AWS · us-east-1 · VPC 10.10.0.0/16',fontsize=15,fontweight='bold',color='#a15912');ax.text(9.75,8.85,'Azure · South Central US',fontsize=15,fontweight='bold',color='#176f9a')
rect(.65,7.65,2.5,.82,'Usuarios + DNS',['multiverso.wimiline.com'],'#a15912');rect(4.8,7.65,3.5,.82,'ALB + certificado ACM',['HTTPS 443 · HTTP redirige a HTTPS'],'#a15912');arrow((3.2,8.06),(4.75,8.06))
rect(.65,6.05,3.5,1.02,'EC2 privada · us-east-1a',['10.10.3.0/24 · Nginx + API','Auto Scaling 2 / 2 / 4'],'#a15912');rect(5.05,6.05,3.5,1.02,'EC2 privada · us-east-1b',['10.10.4.0/24 · Nginx + API','Sin IP pública'],'#a15912');arrow((5.5,7.6),(2.7,7.1));arrow((6.6,7.6),(6.8,7.1))
rect(2.65,4.53,3.85,.93,'RDS PostgreSQL Multi-AZ',['Subredes 10.10.2.0/24 y 10.10.5.0/24','Copia automática · retención 7 días'],'#33816d');arrow((2.45,6.0),(3.5,5.5));arrow((6.85,6.0),(5.65,5.5))
rect(.65,2.55,3.6,1.05,'S3 privado · buckets separados',['Artefacto de aplicación y volcados','Manifiesto SHA-256 de los datos'],'#33816d');rect(5.1,2.55,3.45,1.05,'Respaldo en ambas EC2',['Extrae PostgreSQL y utiliza S3','Envía datos + paquete por HTTPS'],'#a15912');arrow((4.3,3.07),(5.04,3.07),style='<->');arrow((5.9,4.48),(6.65,3.65))
rect(9.95,7.16,5.3,1.12,'Azure Blob · contenedor privado',['Volcados, huellas y paquete por SHA-256','Firewall IP NAT AWS + SAS limitada'],'#176f9a');rect(9.95,5.08,5.3,1.0,'Private Endpoint + DNS',['Subred 10.20.3.0/24','Resolución privada hacia Blob'],'#176f9a');rect(9.95,2.73,5.3,1.05,'VM Azure · integración / prueba',['Subred 10.20.2.0/24 · ARM64','Identidad administrada · restauración'],'#176f9a');arrow((12.6,3.83),(12.6,5.03),color='#176f9a');arrow((12.6,6.13),(12.6,7.1),color='#176f9a')
ax.plot([8.6,9.25,9.25,9.9],[3.07,3.07,7.72,7.72],color='#b66b1c',linewidth=2);arrow((9.4,7.72),(9.9,7.72),color='#b66b1c')
ax.text(.37,1.08,'Operación: CloudWatch + SNS · CloudTrail → S3 · SQS → Lambda · Azure Monitor',fontsize=11,fontweight='bold',color='#1d3851')
ax.text(.37,.78,'Recuperación aislada: Azure Blob → VM → PostgreSQL + aplicación; SHA-256 en ambos archivos.',fontsize=10,color='#34506a')
ax.text(.37,.49,'La SAS vence el 19/12/2026 a las 19:00, hora de Lima; renovar y revisar las IP NAT.',fontsize=10,color='#a15912')
fig.subplots_adjust(left=.01,right=.99,top=.99,bottom=.01)
fig.savefig(r/'Arquitectura_multicloud_implementada_2026-11-20.png',dpi=150,facecolor=fig.get_facecolor());fig.savefig(r/'Arquitectura_multicloud_implementada_2026-11-20.svg',facecolor=fig.get_facecolor());print('Diagrama SVG y PNG generados')

