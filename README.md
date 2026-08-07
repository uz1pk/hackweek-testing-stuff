# hackweek-testing-stuff

Three independent Docker Compose stacks, each brought up on its own.

| | | |
|---|---|---|
| [`llm/`](llm/) | `https://offline.llm:8442` | Open-weight LLM behind a token-checked, OpenAI-compatible `/v1/` API. |
| [`chat/`](chat/) | `https://offline.llm` | Web chat UI for the LLM. |
| [`static/`](static/) | `http://localhost:8080` | Plain nginx serving one HTML page. |

```bash
cd llm    && docker compose up -d
cd chat   && docker compose up -d
cd static && docker compose up -d
```

`chat/` depends on `llm/`: it proxies to it and mounts its certificate, so bring `llm/` up
first and keep the directories side by side. `static/` shares nothing with either.

## TLS

`llm/` and `chat/` are HTTPS only. Both use one static, committed, self-signed certificate at
`llm/certs/` — `CN=offline.llm`, SANs `offline.llm`, `localhost`, `127.0.0.1`, expiring
**2026-09-06**. Nothing is generated at deploy time.

Add to `/etc/hosts` on each client, using the Pi's LAN IP from other machines:

```
127.0.0.1  offline.llm
```

The bearer token and the TLS private key are committed on purpose — local-only credentials so
a fresh clone runs with no setup step. Keep this on a network you trust and don't port-forward
it.

## Clean up

```bash
cd llm && docker compose down
cd chat && docker compose down
cd static && docker compose down
```

Add `-v` to the `llm/` command to delete the downloaded model weights as well.
