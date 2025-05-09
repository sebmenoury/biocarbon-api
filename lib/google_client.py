import os
import gspread
from oauth2client.service_account import ServiceAccountCredentials

# Connexion au client Google Sheets via la clé de service
def get_client():
    scope = [
        "https://spreadsheets.google.com/feeds",
        "https://www.googleapis.com/auth/drive"
    ]

    # Chemin absolu vers le fichier JSON, même si le script est lancé depuis ailleurs
    key_path = os.path.join(os.path.dirname(__file__), "credentials", "greenway-459306-9a34d3da67f4.json")

    creds = ServiceAccountCredentials.from_json_keyfile_name(key_path, scope)
    return gspread.authorize(creds)

# Récupère un onglet par son nom (ex : "Ref-Usages")
def get_worksheet(nom_onglet):
    client = get_client()
    sheet = client.open("Biocarbon Données")  # nom exact du Google Sheet
    return sheet.worksheet(nom_onglet)