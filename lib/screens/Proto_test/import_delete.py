import requests

# Remplace cet ID par celui à supprimer
id_usage = "SEBASTIEN-Réel-2025-Nantes_↔_Paris-20250509T144152"

url = f"https://biocarbon-api.onrender.com/api/uc/usages/{id_usage}"

response = requests.delete(url)

print("Status Code:", response.status_code)
print("Raw Response:", response.text)  # important pour voir le message brut