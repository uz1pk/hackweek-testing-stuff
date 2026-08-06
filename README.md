# hackweek-testing-stuff

Two independent Docker Compose stacks. They share no network, no volumes, and no
configuration — each is brought up on its own.

| | | |
|---|---|---|
| [`llm/`](llm/) | `:8442` | An open-weight LLM behind a token-checked, OpenAI-compatible `/v1/` front door. |
| [`static/`](static/) | `:8080` | Plain nginx serving one HTML page. No auth, no upstream. |

```bash
cd llm    && docker compose up -d
cd static && docker compose up -d
```

Neither uses TLS. Both are localhost-only toys — the LLM stack sends its bearer
token in cleartext, so don't put either on a shared network.

See each subproject's README for details.
