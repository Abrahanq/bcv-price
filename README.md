# API precio BCV (USD y EUR) en JSON | Mini API de tasa oficial Venezuela

Mini API para consultar el precio del dólar BCV y euro BCV en formato JSON, actualizada desde la fuente oficial del Banco Central de Venezuela (BCV).

Este repositorio está pensado para quienes buscan una API del precio del BCV para usar en apps, bots, dashboards o automatizaciones.

## ¿Qué es este proyecto?

`bcv-price` es una mini API sin backend tradicional:

- Extrae la tasa oficial BCV de USD y EUR.
- Guarda histórico en CSV.
- Publica JSON listo para consumo como API.
- Mantiene registros por fecha (sin duplicados).

Si estás buscando: **api precio bcv**, **precio dólar bcv hoy**, **tasa oficial bcv json**, este repo está hecho para ese caso.

## Características principales

- Precio BCV USD y EUR con fecha valor.
- Salida JSON simple y estable para integraciones.
- Estructura ligera y fácil de desplegar.
- Automatizable con GitHub Actions (ejecución programada).

## Estructura del repositorio

- `get_prices.sh`: obtiene y procesa datos desde https://bcv.org.ve
- `csv_to_json.py`: transforma el histórico CSV a JSON
- `prices.csv`: histórico de tasas BCV
- `prices.json`: respuesta tipo API para consumo externo

## Uso rápido

```bash
chmod +x get_prices.sh
./get_prices.sh
python3 csv_to_json.py
```

Resultado:

1. Se consulta la tasa oficial del BCV.
2. Se actualiza `prices.csv`.
3. Se genera `prices.json` para consumo como mini API.

## Formato de respuesta (mini API JSON)

```json
{
  "precios": [
    {
      "fecha": "2026-02-19",
      "usd": 74.12,
      "eur": 80.95
    },
    {
      "fecha": "2026-02-20",
      "usd": 74.30,
      "eur": 81.10
    }
  ]
}
```

Nota: actualmente el JSON publica las 2 últimas cotizaciones registradas.

## Ejemplos de consumo

```bash
cat prices.json
```

```bash
jq '.precios[-1]' prices.json
```

## Casos de uso

- API para precio dólar BCV en bots de Telegram o WhatsApp.
- Tasa BCV para paneles internos y dashboards financieros.
- Automatizaciones con cron y tareas de actualización diaria.
- Integraciones simples donde se necesite tipo de cambio BCV en JSON.

## Consideraciones

- La extracción depende de la estructura HTML de BCV.
- Si BCV cambia su sitio, el script puede requerir ajustes.
- Los datos son informativos y se basan en la fuente oficial consultada.
