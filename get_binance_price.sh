#!/bin/bash

# Obtener precio promedio de USDT/VES en Binance P2P
# tradeType SELL = anuncios donde venden USDT -> precio de VENTA al publico
# tradeType BUY  = anuncios donde compran USDT -> precio de COMPRA al publico

fetch_avg_price() {
    local trade_type=$1
    curl -s -X POST "https://p2p.binance.com/bapi/c2c/v2/friendly/c2c/adv/search" \
        -H "Content-Type: application/json" \
        -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36" \
        -d "{\"asset\":\"USDT\",\"fiat\":\"VES\",\"tradeType\":\"$trade_type\",\"page\":1,\"rows\":10,\"payTypes\":[]}" \
    | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    precios = [float(x['adv']['price']) for x in d.get('data', [])[:10]]
    print(round(sum(precios) / len(precios), 2) if precios else '')
except Exception:
    print('')
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
