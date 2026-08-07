# local-llm

An open-weight LLM behind a token-checked, OpenAI-compatible `/v1/` API on `:8442`.
**HTTPS only** — nothing here answers plain HTTP.

## TLS

`certs/offline.crt` and `certs/offline.key` are static committed files. Nothing is generated
at deploy or start time.

| | |
|---|---|
| Subject | `CN=offline.llm` |
| SANs | `DNS:offline.llm`, `DNS:localhost`, `IP:127.0.0.1` |
| Type | Self-signed, no CA |
| Expires | **2026-09-06** |

Clients pass `certs/offline.crt` as their CA file. To use the name, add `127.0.0.1 offline.llm`
to `/etc/hosts`.

## Start

```bash
docker compose up -d
```

First run downloads the model (~270 MB). `:8442` stays closed until it finishes — follow it
with `docker compose logs -f puller`.

## Examples

List models:

```bash
curl --cacert certs/offline.crt \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  https://localhost:8442/v1/models
```

Chat, streaming:

```bash
curl -N --cacert certs/offline.crt \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H 'Content-Type: application/json' \
  -d '{"model":"smollm2:135m","stream":true,"messages":[{"role":"user","content":"Count to three"}]}' \
  https://localhost:8442/v1/chat/completions
```

By certificate name:

```bash
curl --cacert certs/offline.crt --resolve offline.llm:8442:127.0.0.1 \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  https://offline.llm:8442/v1/models
```

Inspect the served cert:

```bash
openssl s_client -connect localhost:8442 -servername offline.llm </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -dates
```

What the failures look like:

| | |
|---|---|
| `401` | Token missing or wrong |
| `404` | Path outside `/v1/` |
| `400` | You used `http://` against the TLS port |
| curl exit `60` | Missing `--cacert`, or the hostname is not on the cert |

## Configure

`.env` — all values required.

| | |
|---|---|
| `LLM_BEARER_TOKEN` | Token checked by `rest` |
| `LLM_MODEL` | Model pulled on first start |
| `LLM_PORT` | Published port and nginx `listen` |

The token and the private key are committed on purpose: local-only credentials, not secrets.

Config edits need a full recreate — nginx reads config only at start:

```bash
docker compose down && docker compose up -d
```

## Clean up

```bash
docker compose down
```

Model weights survive in the `ollama` volume. To delete them too:

```bash
docker compose down -v
```
