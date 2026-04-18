---
name: memory
description: Store and retrieve information across sessions using local vector memory backed by Ollama embeddings. Use to save important findings, architectural decisions, API patterns, debugging insights, or domain knowledge so they can be recalled in future sessions by semantic search. Requires the nomic-embed-text embedding model.
---

# Vector Memory

Persistent semantic memory across container sessions. Stored in `~/.pi/memory/` (survives restarts via the volume mount).

## Setup (one-time)

```bash
ollama pull nomic-embed-text
```

This is the embedding model used to convert text into vectors for similarity search.

## Invoke

```bash
node /usr/local/lib/memory.js '<json>'
```

## Actions

### add — store a memory
```bash
node /usr/local/lib/memory.js '{"action":"add","content":"The payments service uses idempotency keys stored in Redis with a 24h TTL to prevent duplicate charges.","tags":["payments","redis","architecture"]}'
# → {"ok":true,"id":"lx3k9abc","total":12}
```

### search — recall by meaning (not keywords)
```bash
node /usr/local/lib/memory.js '{"action":"search","query":"how does the payment system avoid duplicate charges?"}'
# → {"ok":true,"results":[{"id":"lx3k9abc","content":"...","score":0.94,...}]}

# Limit results
node /usr/local/lib/memory.js '{"action":"search","query":"redis usage","limit":3}'
```

### list — browse all stored items
```bash
node /usr/local/lib/memory.js '{"action":"list"}'
# → {"ok":true,"count":12,"items":[...]}
```

### delete — remove a specific item
```bash
node /usr/local/lib/memory.js '{"action":"delete","id":"lx3k9abc"}'
```

### clear — wipe all memory
```bash
node /usr/local/lib/memory.js '{"action":"clear"}'
```

## What to Store

Good candidates for memory:
- **Architecture decisions** — "We chose Redis over Memcached because we needed pub/sub"
- **API quirks** — "The Stripe webhook endpoint must return 200 before processing, not after"
- **Bug fixes** — "Race condition in the auth middleware fixed by adding a mutex around token refresh"
- **Domain knowledge** — "An 'invoice' in this codebase is distinct from a 'bill' — invoices are outbound, bills are inbound"
- **Environment facts** — "Staging database is read-only on weekends due to backup jobs"
- **Code patterns** — "All new API routes must use the `withAuth` wrapper and the `validate(schema)` middleware"

## Recommended Workflow

At the start of a session, search memory for relevant context:
```bash
node /usr/local/lib/memory.js '{"action":"search","query":"<description of today's task>"}'
```

At the end of a session, store anything important that was learned:
```bash
node /usr/local/lib/memory.js '{"action":"add","content":"<finding>","tags":["<topic>"]}'
```

## Notes

- **Semantic search** means you don't need exact keywords — "payment deduplication" will find memories about "idempotency keys"
- **Score** in search results is cosine similarity (0–1); scores above 0.8 are highly relevant
- Memory persists in `~/.pi/memory/index.json` — back this up if it's important
- Change the embedding model with `MEMORY_EMBED_MODEL=<model>` env var (must be an Ollama embedding model)
- Memory is **private to this container config** — not shared across different Pi setups
