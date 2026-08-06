# llm-https

A local open-weight LLM behind an HTTPS front door with bearer-token auth.

- **`ollama`** — runs the model. No published ports; reachable only inside the compose network. Weights persist in the `ollama` volume.
- **`rest`** — nginx on `:8443`. Terminates TLS with a self-signed leaf, checks the token, proxies `/v1/` to Ollama.
- Surface is OpenAI-compatible `/v1/` only — anything else, including Ollama's native `/api/*`, returns `404`.

## Start

```bash
./certs/generate-certs.sh
docker compose up -d
```

First `up` downloads the model (~2 GB); later runs reuse the volume copy.

## Call it

```bash
curl --cacert certs/llm-cert.pem \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H 'Content-Type: application/json' \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"Why is the sky blue?"}]}' \
  https://localhost:8443/v1/chat/completions
```

- Use `localhost`, not `127.0.0.1` — the cert has no IP SAN.
- Add `"stream": true` (with `curl -N`) for SSE.
- Any OpenAI SDK works: `base_url="https://localhost:8443/v1"`, plus `SSL_CERT_FILE=$PWD/certs/llm-cert.pem` so it trusts the leaf.

## Configure

- `.env` holds `LLM_BEARER_TOKEN` and `LLM_MODEL` — the single source of truth for the server.
- The committed token is a **deliberately fake local-dev credential**, not a secret. Change it if this ever leaves localhost.
- Rotate it: edit `.env`, then `docker compose restart rest`.

## Notes

- To pick up config edits use `docker compose down` then `up -d` — nginx reads its config only at start, so `stop`/`start` keeps the old one. Weights survive either way.
- CPU-only by design (Docker can't reach Apple Silicon's GPU). A 3B Q4 model is comfortable; 13B+ gets slow.
- If `ollama pull` fails with `x509: certificate signed by unknown authority`, your network intercepts TLS: drop your CA at `certs/extra-ca.crt` and `docker compose restart ollama`.
