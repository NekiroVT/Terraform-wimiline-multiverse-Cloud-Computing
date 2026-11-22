"""Terraform lifecycle for S3 in AWS Academy, whose SCP denies GetBucketObjectLockConfiguration."""
import json, subprocess, sys

action, bucket = sys.argv[1:]
def call(*args, check=True):
    return subprocess.run(["aws", "s3api", *args, "--region", "us-east-1", "--no-cli-pager"], text=True, capture_output=True, check=check)
if action == "ensure":
    p = call("head-bucket", "--bucket", bucket, check=False)
    if p.returncode:
        q = call("create-bucket", "--bucket", bucket, check=False)
        if q.returncode:
            sys.stderr.write(q.stderr); sys.exit(q.returncode)
    print("Bucket gestionado:", bucket)
elif action == "destroy":
    while True:
        data=json.loads(call("list-object-versions", "--bucket", bucket, "--output", "json").stdout)
        entries=[{"Key": x["Key"], "VersionId": x["VersionId"]} for x in data.get("Versions", []) + data.get("DeleteMarkers", [])]
        if not entries: break
        # DeleteObjects accepts at most 1,000 versions per request.
        for offset in range(0, len(entries), 1000):
            batch = entries[offset:offset + 1000]
            with __import__("tempfile").NamedTemporaryFile(mode="w",encoding="utf-8",suffix=".json",delete=False) as f:
                json.dump({"Objects":batch,"Quiet":True},f); file=f.name
            try:
                result=call("delete-objects", "--bucket", bucket, "--delete", "file://"+file)
                obj=json.loads(result.stdout or "{}")
                if obj.get("Errors"): raise RuntimeError("No se pudieron borrar todas las versiones")
            finally: __import__("os").unlink(file)
    call("delete-bucket", "--bucket", bucket)
    print("Bucket eliminado:", bucket)
else:
    raise SystemExit("Acción desconocida")
