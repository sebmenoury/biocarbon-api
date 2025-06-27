import gspread

import os
import json
import gspread
from google.oauth2.service_account import Credentials

# Charger les credentials depuis une variable d'environnement
service_account_info = json.loads(os.environ["GOOGLE_CREDENTIALS_JSON"])

# Créer le client gspread
creds = Credentials.from_service_account_info(service_account_info, scopes=[
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
])
gc = gspread.authorize(creds)

sh = gc.open("Biocarbon Données") 
sheet_uc_postes = sh.worksheet("UC-Postes")