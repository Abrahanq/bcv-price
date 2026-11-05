#!/bin/bash

set -euo pipefail

normalize_rate() {
    local value
    value=$(echo "$1" | xargs)

    # BCV usa coma decimal y puntos como separadores de miles.
    if [[ "$value" == *,* ]]; then
        value=${value//./}
        value=${value//,/.}
    fi

    if [[ ! "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "Error: valor de tasa inválido: '$1' (normalizado: '$value')" >&2
        return 1
    fi

    printf '%s\n' "$value"
}

# Descargar la página del BCV una sola vez
html=$(curl -k -s "https://bcv.org.ve" 2>/dev/null)

if [ -z "$html" ]; then
    echo "Error: No se pudo descargar la página del BCV"
    exit 1
fi

# Extraer fecha del "Fecha Valor"
fecha=$(echo "$html" | grep "Fecha Valor" | grep -oP 'content="\K[^"]+' | cut -d'T' -f1)

# Extraer precio USD
usd=$(echo "$html" | grep 'id="dolar"' -A 10 | grep -oP '<strong[^>]*>\K[^<]+')

# Extraer precio EUR
eur=$(echo "$html" | grep 'id="euro"' -A 10 | grep -oP '<strong[^>]*>\K[^<]+')

# Validar que se extrajeron los datos
if [ -z "$fecha" ] || [ -z "$usd" ] || [ -z "$eur" ]; then
    echo "Error: No se pudieron extraer todos los datos"
    echo "Fecha: $fecha"
    echo "USD: $usd"
    echo "EUR: $eur"
    exit 1
fi

# Limpiar espacios en blanco
fecha=$(echo "$fecha" | xargs)

# Normalizar tasas y validar antes de escribir el CSV.
usd=$(normalize_rate "$usd") || {
    echo "Error: USD extraído del BCV no es válido: '$usd'" >&2
    exit 1
}
eur=$(normalize_rate "$eur") || {
    echo "Error: EUR extraído del BCV no es válido: '$eur'" >&2
    exit 1
}

# Crear o actualizar CSV
csv_file="prices.csv"

if [ ! -f "$csv_file" ]; then
    # Crear archivo con encabezados
    echo "Fecha,USD,EUR" > "$csv_file"
fi

# Verificar si la fecha ya existe en el CSV
if grep -q "^$fecha," "$csv_file"; then
    echo "⚠ La fecha $fecha ya existe en el CSV. No se agregará duplicado."
    # Aún así generar JSON
    python3 csv_to_json.py
    exit 0
fi

# Agregar nueva fila solo si la fecha no existe
echo "$fecha,$usd,$eur" >> "$csv_file"

echo "✓ CSV actualizado: Fecha=$fecha, USD=$usd, EUR=$eur"

# Generar JSON desde el CSV
python3 csv_to_json.py
