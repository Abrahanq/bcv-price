#!/usr/bin/env python3
"""
Convierte el archivo prices.csv a prices.json (ultimas dos cotizaciones)
y a historico.json (todas las cotizaciones).
"""
import csv
import json
import os

def csv_to_json(csv_file="prices.csv", json_file="prices.json",
                history_file="historico.json"):
    """
    Convierte CSV a JSON

    Args:
        csv_file: Ruta del archivo CSV
        json_file: Ruta del JSON con las ultimas dos cotizaciones
        history_file: Ruta del JSON con el historico completo
    """
    precios = []

    # Leer CSV
    if not os.path.exists(csv_file):
        print(f"Error: El archivo {csv_file} no existe")
        return False

    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                precios.append({
                    "fecha": row['Fecha'],
                    "usd": float(row['USD']),
                    "eur": float(row['EUR'])
                })

        # Ordenar por fecha y eliminar fechas duplicadas (gana la ultima fila)
        por_fecha = {p["fecha"]: p for p in precios}
        historico = [por_fecha[k] for k in sorted(por_fecha)]

        # Historico completo (compacto, sin indentar, para que pese menos)
        with open(history_file, 'w', encoding='utf-8') as f:
            json.dump({"precios": historico}, f, ensure_ascii=False,
                      separators=(',', ':'))

        # Solo conservar las ultimas dos cotizaciones del CSV.
        ultimos = historico[-2:]

        # Escribir JSON
        output = {"precios": ultimos}
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(output, f, ensure_ascii=False, indent=2)

        print(f"✓ Conversión completada: {csv_file} → {json_file}, {history_file} "
              f"({len(historico)} fechas)")
        return True

    except Exception as e:
        print(f"Error durante la conversión: {e}")
        return False

if __name__ == "__main__":
    csv_to_json()
