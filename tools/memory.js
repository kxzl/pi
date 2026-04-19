#!/usr/bin/env node
// Vector memory tool for the Pi agent.
// Stores text with Ollama embeddings; retrieves by semantic similarity.
//
// Usage (via bash tool):
//   node /usr/local/lib/memory.js '<json>'
//
// Requires: ollama pull nomic-embed-text (or set MEMORY_EMBED_MODEL)
//
// Actions:
//   add    {content, tags?}        Store text, returns id
//   search {query, limit?}         Find semantically similar items (default top 5)
//   list   {}                      List all stored items (content truncated to 200 chars)
//   delete {id}                    Remove a specific item
//   clear  {}                      Wipe all stored memory

const fs = require('fs');
const path = require('path');

const MEMORY_DIR  = '/home/piuser/.pi/memory';
const MEMORY_FILE = path.join(MEMORY_DIR, 'index.json');
const EMBED_MODEL = process.env.MEMORY_EMBED_MODEL || 'nomic-embed-text';
const OLLAMA_URL  = process.env.OLLAMA_HOST || process.env.OLLAMA_URL || 'http://localhost:11434';

function load() {
  try {
    if (fs.existsSync(MEMORY_FILE))
      return JSON.parse(fs.readFileSync(MEMORY_FILE, 'utf8'));
  } catch {}
  return { items: [] };
}

function save(store) {
  fs.mkdirSync(MEMORY_DIR, { recursive: true });
  fs.writeFileSync(MEMORY_FILE, JSON.stringify(store, null, 2));
}

async function embed(text) {
  const res = await fetch(`${OLLAMA_URL}/api/embeddings`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ model: EMBED_MODEL, prompt: text }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Ollama embedding failed (${res.status}): ${body}`);
  }
  return (await res.json()).embedding;
}

function cosine(a, b) {
  let dot = 0, magA = 0, magB = 0;
  for (let i = 0; i < a.length; i++) {
    dot  += a[i] * b[i];
    magA += a[i] * a[i];
    magB += b[i] * b[i];
  }
  return dot / (Math.sqrt(magA) * Math.sqrt(magB));
}

function makeId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

async function run() {
  const cmd = JSON.parse(process.argv[2] || '{}');
  const store = load();

  switch (cmd.action) {
    case 'add': {
      if (!cmd.content) { out({ ok: false, error: 'content is required' }); return; }
      const embedding = await embed(cmd.content);
      const item = {
        id: makeId(),
        content: cmd.content,
        tags: cmd.tags || [],
        embedding,
        timestamp: new Date().toISOString(),
      };
      store.items.push(item);
      save(store);
      out({ ok: true, id: item.id, total: store.items.length });
      break;
    }

    case 'search': {
      if (!cmd.query) { out({ ok: false, error: 'query is required' }); return; }
      if (store.items.length === 0) { out({ ok: true, results: [] }); return; }
      const qEmbed = await embed(cmd.query);
      const limit  = cmd.limit || 5;
      const scored = store.items
        .map(({ id, content, tags, timestamp, embedding }) => ({
          id, content, tags, timestamp,
          score: cosine(qEmbed, embedding),
        }))
        .sort((a, b) => b.score - a.score)
        .slice(0, limit);
      out({ ok: true, results: scored });
      break;
    }

    case 'list': {
      const items = store.items.map(({ id, content, tags, timestamp }) => ({
        id, tags, timestamp, content: content.slice(0, 200),
      }));
      out({ ok: true, count: items.length, items });
      break;
    }

    case 'delete': {
      if (!cmd.id) { out({ ok: false, error: 'id is required' }); return; }
      const before = store.items.length;
      store.items = store.items.filter(i => i.id !== cmd.id);
      save(store);
      out({ ok: true, removed: before - store.items.length });
      break;
    }

    case 'clear': {
      const count = store.items.length;
      store.items = [];
      save(store);
      out({ ok: true, cleared: count });
      break;
    }

    default:
      out({ ok: false, error: 'Unknown action: ' + cmd.action });
  }
}

function out(obj) { console.log(JSON.stringify(obj)); }

run().catch(err => {
  out({ ok: false, error: err.message });
  process.exit(1);
});
