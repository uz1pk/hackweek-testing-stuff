# local-llm

A local open-weight LLM behind a token-checked HTTP front door.

- **`ollama`** — runs the model. No published ports; reachable only inside the compose network. Weights persist in the `ollama` volume.
- **`rest`** — nginx on `:8442`. Checks the bearer token and proxies `/v1/` to Ollama.
- Surface is OpenAI-compatible `/v1/` only — anything else, including Ollama's native `/api/*`, returns `404`.
- **Plain HTTP, no TLS.** The token crosses the wire in cleartext, so this is a localhost-only toy. Don't put it on a shared network.

## Start

```bash
docker compose up -d
```

First `up` downloads the model (~270 MB for the default `smollm2:135m`); later runs reuse the volume copy.

## Call it

Chat completion:

```bash
curl -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H 'Content-Type: application/json' \
  -d '{"model":"smollm2:135m","messages":[{"role":"user","content":"Why is the sky blue?"}]}' \
  http://localhost:8442/v1/chat/completions
```

Stream it — `-N` stops curl buffering the SSE:

```bash
curl -N -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H 'Content-Type: application/json' \
  -d '{"model":"smollm2:135m","stream":true,"messages":[{"role":"user","content":"Count to three"}]}' \
  http://localhost:8442/v1/chat/completions
```

Plain completion, no chat template:

```bash
curl -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H 'Content-Type: application/json' \
  -d '{"model":"smollm2:135m","prompt":"The capital of France is","max_tokens":10}' \
  http://localhost:8442/v1/completions
```

List what's actually in the volume — handy when a request 404s on a model you thought you'd pulled:

```bash
curl -H "Authorization: Bearer llm-local-dev-token-change-me" \
  http://localhost:8442/v1/models
```

Two failure modes worth recognising, both JSON:

```bash
curl http://localhost:8442/v1/models     # 401 invalid_api_key  — token missing or wrong
curl http://localhost:8442/api/tags      # 404                  — outside /v1/
```

Any OpenAI SDK works against `base_url="http://localhost:8442/v1"`, with the token as the API key.

## Configure

`.env` is the single source of truth — every value is required, and `docker compose up` fails with a named error if one is missing.

| | |
|---|---|
| `LLM_BEARER_TOKEN` | The token `rest` checks. Rotate with an edit plus `docker compose down && up -d`. |
| `LLM_MODEL` | What `puller` fetches on first start. |
| `LLM_PORT` | Feeds both the published port and nginx's `listen`, so the two can't disagree. |

The committed token is a **deliberately fake local-dev credential**, not a secret.

## Notes

- To pick up config edits use `docker compose down` then `up -d` — nginx reads its config only at start, so `stop`/`start` keeps the old one. Weights survive either way.
- CPU-only by design (Docker can't reach Apple Silicon's GPU), so the default is `smollm2:135m` — tiny and dumb, but fast enough to test the server with. Swap `LLM_MODEL` for something bigger (`llama3.2:1b`, or `llama3.2` for 3B) if you want coherent answers and can wait.
- If `ollama pull` fails with `x509: certificate signed by unknown authority`, your network intercepts TLS. Drop that CA at `ca/extra-ca.crt` and `docker compose up -d ollama`; both `ollama` and `puller` copy it into their trust store at boot. On a Palantir machine:

  ```bash
  security find-certificate -a -c "Palantir PAN Firewall CA 2023" \
    -p /Library/Keychains/System.keychain > ca/extra-ca.crt
  ```
