# Running on a Raspberry Pi

How to get `https://offline.llm:8442/v1/chat/completions` working locally on the Pi, with TLS
and bearer-token auth, using only the `llm/` stack.

Nothing is generated on the Pi. The certificate and key are committed, so a clone has
everything it needs.

## Requirements

**64-bit Raspberry Pi OS.** `ollama/ollama` publishes `arm64` only — there is no `arm/v7`
build, so a 32-bit install cannot run this at all. Check:

```bash
uname -m
```

`aarch64` is correct. If it says `armv7l`, reflash with the 64-bit image first.

A Pi 4 or 5 with 4 GB is comfortable for `smollm2:135m`. Expect tens of seconds per reply.

## Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Log out and back in for the group change to take effect, then confirm:

```bash
docker compose version
```

## Clone and start

```bash
git clone <this repo>
cd <repo>/llm
docker compose up -d
```

The first run downloads the model (~270 MB). Port 8442 stays closed until it finishes —
`rest` waits on the download. Follow it:

```bash
docker compose logs -f puller
```

When `puller` exits and `rest` is up, you are ready:

```bash
docker compose ps
```

## Resolve the hostname

The certificate is issued for `offline.llm`, so the Pi has to resolve that name:

```bash
echo "127.0.0.1  offline.llm" | sudo tee -a /etc/hosts
```

## Call it

```bash
curl --cacert certs/offline.crt \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H "Content-Type: application/json" \
  -d '{"model":"smollm2:135m","messages":[{"role":"user","content":"What color is the sky?"}]}' \
  https://offline.llm:8442/v1/chat/completions
```

Streaming, so you see tokens instead of waiting:

```bash
curl -N --cacert certs/offline.crt \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  -H "Content-Type: application/json" \
  -d '{"model":"smollm2:135m","stream":true,"messages":[{"role":"user","content":"Count to three"}]}' \
  https://offline.llm:8442/v1/chat/completions
```

Quick health check that does not run inference:

```bash
curl --cacert certs/offline.crt \
  -H "Authorization: Bearer llm-local-dev-token-change-me" \
  https://offline.llm:8442/v1/models
```

## From other machines on the LAN

Use the Pi's address instead of loopback in the other machine's `/etc/hosts`:

```bash
hostname -I | awk '{print $1}'
```

Then on the client, with that address:

```
192.168.x.x  offline.llm
```

Copy `llm/certs/offline.crt` to the client and pass it with `--cacert`. The same URL then
works from anywhere on the network.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `curl: (7) Failed to connect` | `rest` not up yet — the model is still downloading. Check `docker compose logs puller`. |
| `curl: (6) Could not resolve host` | Missing the `/etc/hosts` entry. |
| `curl: (77)` | The `--cacert` path is wrong. From `llm/` it is `certs/offline.crt`. |
| `curl: (60)` | Certificate expired, or you used a hostname not on it. |
| `400` | You used `http://` — this port is HTTPS only. |
| `401` | Token does not match `LLM_BEARER_TOKEN` in `llm/.env`. |
| `exec format error` in logs | 32-bit OS. Reflash with 64-bit. |
| Very slow replies | Normal on Pi-class CPUs. |

The certificate expires **2026-09-06**. After that every call fails verification until it is
rotated; the command is in [`llm/README.md`](llm/README.md).

## Clean up

```bash
docker compose down
```

Model weights survive in the `ollama` volume. To remove those too:

```bash
docker compose down -v
```
