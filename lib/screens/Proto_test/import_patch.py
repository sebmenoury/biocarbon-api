import requests

# Remplace cet ID par celui reçu après le POST
id_usage = "SEBASTIEN-Réel-2025-Nantes_↔_Paris-20250509T144152"

url = f"https://biocarbon-api.onrender.com/api/uc/usages/{id_usage}"

# Données à mettre à jour
data = {
    "Quantite": 2,
    "Emission_Calculee": 3.2
}

response = requests.patch(url, json=data)

print("Status Code:", response.status_code)
print("Response:", response.json())