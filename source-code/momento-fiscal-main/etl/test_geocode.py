import requests
import time

# Teste CEP Brasília
cep = "70040902"
cep_formatado = f"{cep[:5]}-{cep[5:]}"

# ViaCEP
r = requests.get(f"https://viacep.com.br/ws/{cep_formatado}/json/")
data = r.json()
print(f"ViaCEP: {data}")

# Monta endereço
endereco = f"{data['localidade']}, {data['uf']}, Brasil"
print(f"\nEndereço simplificado: {endereco}")

# Nominatim
time.sleep(1)
params = {
    "q": endereco,
    "format": "json",
    "limit": 1,
    "countrycodes": "br"
}
headers = {"User-Agent": "Momento-Fiscal/1.0"}
r2 = requests.get("https://nominatim.openstreetmap.org/search", params=params, headers=headers)
results = r2.json()

if results:
    result = results[0]
    print(f"\nNominatim encontrou:")
    print(f"Lat: {result['lat']}, Lon: {result['lon']}")
    print(f"Display name: {result['display_name']}")
else:
    print("\nNominatim não encontrou resultado")
