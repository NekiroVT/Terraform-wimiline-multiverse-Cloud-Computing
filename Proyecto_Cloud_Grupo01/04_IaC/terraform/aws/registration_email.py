import json
import logging
import os
import re
import smtplib
import ssl
from email.message import EmailMessage

import boto3

LOG = logging.getLogger()
LOG.setLevel(logging.INFO)
SENDER = os.environ.get("GMAIL_SENDER", "wimiline.info@gmail.com")
PARAMETER = os.environ.get("GMAIL_PASSWORD_PARAMETER", "/multiverso/prod/gmail-app-password")


def connect():
    secret = boto3.client("ssm").get_parameter(Name=PARAMETER, WithDecryption=True)["Parameter"]["Value"]
    client = smtplib.SMTP("smtp.gmail.com", 587, timeout=12)
    try:
        client.ehlo()
        client.starttls(context=ssl.create_default_context())
        client.ehlo()
        client.login(SENDER, secret)
        return client
    except Exception:
        client.close()
        raise


def handler(event, context):
    if event.get("check") == "smtp-auth":
        with connect():
            return {"smtp_auth": "ok"}

    failures = []
    for record in event.get("Records", []):
        message_id = record.get("messageId", "")
        try:
            payload = json.loads(record["body"])
            recipient = payload.get("email", "")
            if payload.get("type") != "user_registered" or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", recipient):
                raise ValueError("Invalid registration event")
            # Las direcciones reservadas para pruebas no generan correo externo.
            if recipient.lower().endswith(".invalid"):
                LOG.info("Synthetic test event acknowledged for message %s", message_id)
                continue
            message = EmailMessage()
            message["Subject"] = "Bienvenido a Wimiline"
            message["From"] = SENDER
            message["To"] = recipient
            message.set_content("¡Bienvenido a Wimiline! Tu cuenta se registró correctamente.\n")
            with connect() as client:
                client.send_message(message)
            LOG.info("Welcome email accepted by SMTP for message %s", message_id)
        except Exception as exc:
            LOG.error("Registration email failed for message %s: %s", message_id, type(exc).__name__)
            failures.append({"itemIdentifier": message_id})
    return {"batchItemFailures": failures}
