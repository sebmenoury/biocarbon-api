import requests

url = "https://biocarbon-api.onrender.com/api/uc/usages"

data = {
  "Code_Individu": "SEBASTIEN",
  "Type_Temps": "Réel",
  "Valeur_Temps": 2025,
  "Date_Enregistrement": "2025-05-09",
  "Type_Categorie": "Déplacement",
  "Sous_Categorie": "Train",
  "Nom_Usage": "Nantes ↔ Paris",
  "Quantite": 1,
  "Distance_km": 400,
  "Unite": "km",
  "Facteur_Emission": 4,
  "Emission_Calculee": 1.6
}

response = requests.post(url, json=data)
print(response.status_code)
print(response.json())