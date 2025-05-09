import os
import gspread
from oauth2client.service_account import ServiceAccountCredentials

def get_client():
    scope = [
        "https://spreadsheets.google.com/feeds",
        "https://www.googleapis.com/auth/drive"
    ]
    key_path = "/etc/secrets/greenway_459306.json"

    print(f"🔍 Lecture clé depuis : {key_path}")
    if not os.path.exists(key_path):
        raise FileNotFoundError(f"❌ Clé Google absente : {key_path}")

    creds = ServiceAccountCredentials.from_json_keyfile_name(key_path, scope)
    return gspread.authorize(creds)

def get_worksheet(sheet_name, tab_name):
    client = get_client()
    return client.open(sheet_name).worksheet(tab_name)