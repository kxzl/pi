---
name: duckdb
description: Run SQL queries directly over CSV, JSON, Parquet, and log files — no database server needed. Use when you need to analyse structured data files, query test output, explore a database export, aggregate logs, join multiple data files, or answer questions about datasets. Also works with remote files over HTTP. Much faster and more expressive than awk/grep for tabular data.
---

# DuckDB — In-Process SQL over Files

SQL engine that queries files directly. No server, no imports — just point it at a file and write SQL.

## Quick Start

```bash
# Query a CSV directly
duckdb -c "SELECT * FROM '/workspace/data.csv' LIMIT 10"

# Describe the schema of a file
duckdb -c "DESCRIBE SELECT * FROM '/workspace/data.csv'"

# JSON file
duckdb -c "SELECT * FROM '/workspace/output.json' LIMIT 5"

# Parquet
duckdb -c "SELECT * FROM '/workspace/results.parquet'"
```

## Schema Exploration

```bash
# What columns does the file have and what are their types?
duckdb -c "DESCRIBE SELECT * FROM '/workspace/data.csv'"

# How many rows?
duckdb -c "SELECT COUNT(*) FROM '/workspace/data.csv'"

# Sample of values in each column
duckdb -c "SUMMARIZE SELECT * FROM '/workspace/data.csv'"
```

## Filtering and Aggregation

```bash
# Filter rows
duckdb -c "SELECT * FROM '/workspace/data.csv' WHERE status = 'error'"

# Count by category
duckdb -c "SELECT status, COUNT(*) AS n FROM '/workspace/data.csv' GROUP BY status ORDER BY n DESC"

# Top 10 by value
duckdb -c "SELECT name, SUM(amount) AS total FROM '/workspace/sales.csv' GROUP BY name ORDER BY total DESC LIMIT 10"

# Date range filter (DuckDB auto-parses ISO dates)
duckdb -c "SELECT * FROM '/workspace/events.csv' WHERE timestamp > '2024-01-01'"
```

## Multiple Files and Glob

```bash
# Query all CSVs in a directory at once
duckdb -c "SELECT * FROM '/workspace/logs/*.csv' LIMIT 20"

# Union multiple files with a filename column
duckdb -c "SELECT filename, * FROM read_csv('/workspace/reports/*.csv', filename=true)"
```

## JSON and Nested Data

```bash
# Flat JSON array
duckdb -c "SELECT * FROM '/workspace/results.json'"

# Nested JSON — unnest arrays
duckdb -c "SELECT id, unnest(tags) AS tag FROM '/workspace/data.json'"

# Extract nested fields
duckdb -c "SELECT json_extract(payload, '$.user.id') AS user_id FROM '/workspace/events.json'"
```

## Joining Files

```bash
# Join CSV and JSON
duckdb -c "
  SELECT u.name, o.total
  FROM '/workspace/users.csv' u
  JOIN '/workspace/orders.json' o ON u.id = o.user_id
"
```

## Exporting Results

```bash
# Export query result to CSV
duckdb -c "COPY (SELECT * FROM '/workspace/data.csv' WHERE status='active') TO '/workspace/active.csv'"

# Export to JSON
duckdb -c "COPY (SELECT status, COUNT(*) AS n FROM '/workspace/data.csv' GROUP BY status) TO '/tmp/summary.json' (FORMAT JSON)"

# Export to Parquet
duckdb -c "COPY (SELECT * FROM '/workspace/data.csv') TO '/workspace/data.parquet' (FORMAT PARQUET)"
```

## Persistent Database

```bash
# Create/open a real DuckDB file for multi-step analysis
duckdb /workspace/analysis.db -c "CREATE TABLE events AS SELECT * FROM '/workspace/data.csv'"
duckdb /workspace/analysis.db -c "SELECT COUNT(*) FROM events"
```

## Analysing Test Output / Logs

```bash
# Parse JSON test output (e.g. Jest --json)
duckdb -c "
  SELECT
    json_extract(t.value, '$.ancestorTitles[0]') AS suite,
    json_extract(t.value, '$.title') AS test,
    json_extract(t.value, '$.status') AS status,
    json_extract(t.value, '$.duration') AS ms
  FROM (
    SELECT unnest(json_extract('/tmp/jest-results.json', '$.testResults[*].testResults[*]')) AS t
  )
  WHERE json_extract(t.value, '$.status') = 'failed'
"

# Analyse structured access logs (combined log format)
duckdb -c "
  SELECT
    strftime(epoch_ms(timestamp_ms), '%H:00') AS hour,
    status_code,
    COUNT(*) AS requests
  FROM read_csv('/workspace/access.log',
    columns={'timestamp_ms': 'BIGINT', 'method': 'VARCHAR', 'path': 'VARCHAR', 'status_code': 'INTEGER'})
  GROUP BY hour, status_code
  ORDER BY hour, status_code
"
```

## Window Functions and Analytics

```bash
# Running total
duckdb -c "
  SELECT date, revenue,
    SUM(revenue) OVER (ORDER BY date) AS cumulative
  FROM '/workspace/sales.csv'
"

# Percentile
duckdb -c "SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_ms) AS p95 FROM '/workspace/timings.csv'"

# Lag/lead for change detection
duckdb -c "
  SELECT date, value,
    value - LAG(value) OVER (ORDER BY date) AS delta
  FROM '/workspace/metrics.csv'
"
```

## Tips

- DuckDB auto-detects CSV delimiters, headers, and types — no config needed for most files
- Use `SUMMARIZE` to get min/max/mean/quantiles for every column in one query
- Pipe output through `jq` when using `--json` flag for further processing
- For very large files, add `LIMIT` first to explore structure before running full aggregations
