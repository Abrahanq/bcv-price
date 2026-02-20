# 🇻🇪 BCV Price Feed

Pequeño proyecto que funciona como una **API ligera** para consultar el precio oficial del **dólar (USD)** y **euro (EUR)** del Banco Central de Venezuela (BCV).

Obtiene los datos desde la web del BCV, los guarda en CSV y genera un JSON listo para consumir desde cualquier app, bot o dashboard.

---

## ✨ ¿Qué hace este repo?

- Consulta la tasa oficial del BCV para **USD** y **EUR**.
- Extrae también la **fecha valor**.
- Guarda histórico en `prices.csv`.
- Genera `prices.json` en formato tipo API.
- Evita duplicar registros cuando la fecha ya existe.

---

## 📦 Estructura

- `get_prices.sh`: descarga y procesa datos desde https://bcv.org.ve
- `csv_to_json.py`: convierte el CSV a JSON
- `prices.csv`: histórico de tasas
- `prices.json`: salida para consumo externo

---

## 🚀 Uso rápido

```bash
chmod +x get_prices.sh
./get_prices.sh
```

Al ejecutar, el script:
1. Consulta BCV.
2. Actualiza `prices.csv`.
3. Regenera `prices.json`.

---

## 🔌 Formato “API” (`prices.json`)

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

> Nota: actualmente se publican las **2 últimas cotizaciones** registradas en el CSV.

---

## 💡 Ejemplo de consumo

```bash
cat prices.json
```

Con `jq` (si lo tienes instalado):

```bash
jq '.precios[-1]' prices.json
```

---

## ⚠️ Consideraciones

- Este proyecto depende de la estructura HTML del sitio del BCV.
- Si BCV cambia su markup, puede requerir ajustes en el scraping.
- Las tasas mostradas son informativas según la fuente oficial consultada.

---

## 🤝 Ideal para

- Bots de Telegram/WhatsApp
- Widgets de tipo de cambio
- Dashboards financieros internos
- Automatizaciones con cron
