import gspread

gc = gspread.service_account(filename='credentials.json')  # ou autre méthode selon ton setup
sh = gc.open("Biocarbon Données")  # adapte le nom ici
sheet_uc_postes = sh.worksheet("UC-Postes")