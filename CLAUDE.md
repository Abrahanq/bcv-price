# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`bcv-price` is a backend-less mini API for Venezuela's official BCV (Banco Central de Venezuela) USD/EUR exchange rates. There is no server: a shell script scrapes bcv.org.ve, appends to a CSV history, and a Python script converts that CSV into a JSON file that is committed directly to the repo and consumed as a static "API" (e.g. via raw GitHub URL or `jq`).

## Pipeline / architecture

The whole system is two scripts run in sequence, orchestrated daily by GitHub Actions:

1. `get_prices.sh` — downloads `https://bcv.org.ve` with `curl -k`, greps the HTML for the "Fecha Valor" date and the `id="dolar"` / `id="euro"` blocks' `<strong>` values, normalizes decimal commas to dots, and appends a `fecha,usd,eur` row to `prices.csv` (skips if that date already exists — no duplicate rows per day). It then always invokes `csv_to_json.py`.
2. `csv_to_json.py` — reads `prices.csv`, keeps only the **last 2 rows**, and writes them to `prices.json` under a `{"precios": [...]}` key. This 2-row truncation is intentional (see README: "el JSON publica las 2 últimas cotizaciones").
3. `.github/workflows/daily-price-BCV.yml` — runs on a cron schedule (21:30 UTC primary attempt, 22:00 UTC weekday retry) plus `workflow_dispatch`. It runs both scripts, then commits `prices.csv`/`prices.json` back to `main` directly (`git commit` + `git pull --rebase` + `git push`), skipping the commit if nothing changed.

Because scraping depends on BCV's HTML structure, `get_prices.sh`'s grep/regex extraction is the most fragile part of the repo — if BCV changes their markup, extraction silently breaks (the script does validate that fecha/usd/eur are all non-empty and exits with an error if not).

## Binance P2P pipeline (USDT/VES)

A second, independent pipeline tracks the Binance P2P USDT/VES rate (what Venezuelans commonly mean by "precio Binance", distinct from BCV's official rate):

1. `get_binance_price.sh` — POSTs to Binance's internal (undocumented) P2P endpoint `https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search` twice: `tradeType: "SELL"` (ads where people sell USDT → the price the public pays to *buy*, i.e. "precio de venta") and `tradeType: "BUY"` (ads where people buy USDT → the price the public gets when *selling*, i.e. "precio de compra"). Each call averages the top 10 ads' prices. Requires a browser-like `User-Agent` header or the request gets a 403 (bot detection) — this must run server-side (GitHub Actions runner), never from client-side JS, since the endpoint isn't CORS-enabled for external origins anyway.
2. Writes `binance_price.json` as a single **overwritten snapshot** (`{"actualizado", "compra", "venta"}`), not an appended history like `prices.csv` — the P2P rate changes continuously, so only "now" is meaningful.
3. `.github/workflows/binance-price.yml` — cron every 10 minutes (`*/10 * * * *`) + `workflow_dispatch`, commits `binance_price.json` only when the value changed. Note GitHub Actions cron timing isn't exact under load, so real-world cadence can drift beyond 10 minutes.

This endpoint is unofficial/internal to Binance's website (not their public REST API) and can change or get blocked without notice.

## Common commands

Run the full pipeline locally exactly as CI does:

```bash
chmod +x get_prices.sh
./get_prices.sh          # scrapes BCV, updates prices.csv, then calls csv_to_json.py
```

Regenerate `prices.json` from the existing `prices.csv` without re-scraping:

```bash
python3 csv_to_json.py
```

Inspect the published JSON:

```bash
jq '.precios[-1]' prices.json
```

There is no build, lint, or test tooling in this repo.

## Data files are generated — treat with care

`prices.csv` (full history) and `prices.json` (last 2 entries only) are data outputs, not source code, and are updated automatically by the daily workflow. Avoid hand-editing them except to fix a genuinely bad scraped value; any manual edit to `prices.csv` should preserve the `Fecha,USD,EUR` header and ascending date order, since `csv_to_json.py` just takes the last 2 rows as-is.
