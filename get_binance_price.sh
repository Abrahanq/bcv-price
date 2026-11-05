#!/bin/bash

set -euo pipefail

# Obtener precio promedio de USDT/VES en Binance P2P
# tradeType SELL = anuncios donde venden USDT -> precio de VENTA al publico
# tradeType BUY  = anuncios donde compran USDT -> precio de COMPRA al publico

fetch_avg_price() {
    local trade_type=$1
    curl -sS --fail-with-body -X POST "https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search" \
        -H "Content-Type: application/json" \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36" \
        -d "{\"asset\":\"USDT\",\"fiat\":\"VES\",\"tradeType\":\"$trade_type\",\"page\":1,\"rows\":10,\"payTypes\":[]}" \
    | python3 -c "
import json
import math
import sys

trade_type = \"$trade_type\"

try:
    response = json.load(sys.stdin)
except json.JSONDecodeError as error:
    print(f'Error Binance {trade_type}: respuesta no es JSON válido: {error}', file=sys.stderr)
    raise SystemExit(1)

if not isinstance(response, dict):
    print(f'Error Binance {trade_type}: la respuesta no es un objeto JSON', file=sys.stderr)
    raise SystemExit(1)

if response.get('code') not in (None, '000000', 0):
    print(
        f'Error Binance {trade_type}: code={response.get(\"code\")!r}, '
        f'message={response.get(\"message\")!r}',
        file=sys.stderr,
    )
    raise SystemExit(1)

data = response.get('data')
if not isinstance(data, list) or not data:
    print(f'Error Binance {trade_type}: la respuesta no contiene anuncios', file=sys.stderr)
    raise SystemExit(1)

prices = []
for index, announcement in enumerate(data[:10], start=1):
    raw_price = '<missing>'
    try:
        raw_price = announcement['adv']['price']
        normalized_price = str(raw_price).strip().replace(',', '.')
        price = float(normalized_price)
    except (KeyError, TypeError, ValueError) as error:
        print(
            f'Error Binance {trade_type}: precio inválido en anuncio {index}: '
            f'{raw_price!r} ({error})',
            file=sys.stderr,
        )
        raise SystemExit(1)

    if not math.isfinite(price):
        print(
            f'Error Binance {trade_type}: precio no finito en anuncio {index}: '
            f'{raw_price!r}',
            file=sys.stderr,
        )
        raise SystemExit(1)

    prices.append(price)

print(round(sum(prices) / len(prices), 2))
"
}

venta=$(fetch_avg_price "SELL")
compra=$(fetch_avg_price "BUY")

if [ -z "$venta" ] || [ -z "$compra" ]; then
    echo "Error: no se pudieron obtener los precios de Binance P2P"
    exit 1
fi

fecha=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > binance_price.json <<EOF
{
  "actualizado": "$fecha",
  "compra": $compra,
  "venta": $venta
}
EOF

echo "✓ binance_price.json actualizado: compra=$compra venta=$venta"
