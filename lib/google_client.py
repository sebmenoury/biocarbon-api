import gspread
import os
from oauth2client.service_account import ServiceAccountCredentials

def get_client():
    scope = [
        "https://spreadsheets.google.com/feeds",
        "https://www.googleapis.com/auth/drive"
    ]
    # Chemin vers le fichier JSON dans le dossier credentials
    key_path = os.path.join(os.path.dirname(__file__), "credentials", "greenway-459306-9a34d3da67f4.json")
    creds = ServiceAccountCredentials.from_json_keyfile_name(key_path, scope)
    return gspread.authorize(creds)

def get_worksheet(sheet_name):
    client = get_client()
    sheet = client.open("BioCarbon Données")
    return sheet.worksheet(sheet_name)