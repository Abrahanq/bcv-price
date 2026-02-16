#!/usr/bin/env python3
"""
Convierte el archivo prices.csv a prices.json
"""
import csv
import json
import os

def csv_to_json(csv_file="prices.csv", json_file="prices.json"):
    """
    Convierte CSV a JSON
    
    Args:
        csv_file: Ruta del archivo CSV
        json_file: Ruta del archivo JSON de salida
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
        
        # Escribir JSON
        output = {"precios": precios}
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(output, f, ensure_ascii=False, indent=2)
        
        print(f"✓ Conversión completada: {csv_file} → {json_file}")
        return True
    
    except Exception as e:
        print(f"Error durante la conversión: {e}")
        return False

if __name__ == "__main__":
    csv_to_json()
