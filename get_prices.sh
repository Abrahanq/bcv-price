#!/bin/bash

# Descargar la página del BCV una sola vez
html=$(curl -k -s "https://bcv.org.ve" 2>/dev/null)

if [ -z "$html" ]; then
    echo "Error: No se pudo descargar la página del BCV"
    exit 1
fi

# Extraer fecha del "Fecha Valor"
fecha=$(echo "$html" | grep "Fecha Valor" | grep -oP 'content="\K[^"]+' | cut -d'T' -f1)

# Extraer precio USD
usd=$(echo "$html" | grep 'id="dolar"' -A 10 | sed -n 's/.*<strong>\s*\([^<]*\).*/\1/p' | head -1)

# Extraer precio EUR
eur=$(echo "$html" | grep 'id="euro"' -A 10 | sed -n 's/.*<strong>\s*\([^<]*\).*/\1/p' | head -1)

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
usd=$(echo "$usd" | xargs)
eur=$(echo "$eur" | xargs)

# Dejar solo 2 decimales (formato: XXX.XX) - convertir coma a punto
usd=$(echo "$usd" | sed -E 's/,([0-9]{2}).*/.\1/' | tr ',' '.')
eur=$(echo "$eur" | sed -E 's/,([0-9]{2}).*/.\1/' | tr ',' '.')

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
