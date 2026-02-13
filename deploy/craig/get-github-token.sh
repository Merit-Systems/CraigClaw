#!/bin/bash
# Generate a GitHub App installation token using PyJWT.
# Requires: python3, PyJWT (pip install pyjwt[crypto])
# Requires: ~/.config/craig/github-app-key.pem (private key, not tracked in repo)
python3 -c "
import json, time, urllib.request, jwt

app_id = 2840368
now = int(time.time())
payload = {\"iat\": now - 60, \"exp\": now + 600, \"iss\": app_id}

with open(\"/home/ubuntu/.config/craig/github-app-key.pem\") as f:
    private_key = f.read()

token = jwt.encode(payload, private_key, algorithm=\"RS256\")

req = urllib.request.Request(
    \"https://api.github.com/app/installations/109362995/access_tokens\",
    method=\"POST\",
    headers={
        \"Authorization\": f\"Bearer {token}\",
        \"Accept\": \"application/vnd.github+json\",
    }
)
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())
print(data[\"token\"])
"
