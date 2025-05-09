import gspread
from oauth2client.service_account import ServiceAccountCredentials

# Définir la portée d’accès
scope = [
    "https://spreadsheets.google.com/feeds",
    "https://www.googleapis.com/auth/drive"
]

# Charger le fichier JSON (mets ici le chemin exact si différent)
creds = ServiceAccountCredentials.from_json_keyfile_name(
    "C:/Users/7311576R/Documents/streamlit_test/carbone_web/greenway-459306-9a34d3da67f4.json", scope
)

# Autoriser l’accès
client = gspread.authorize(creds)

# Ouvrir ton Google Sheet par son nom (exact, tel qu’il s'affiche dans Drive)
spreadsheet = client.open("Biocarbon Données")  # adapte le nom si nécessaire
files = client.list_spreadsheet_files()
for f in files:
    print(f["name"])

# Afficher les noms des onglets (worksheets)
worksheets = spreadsheet.worksheets()
print("✅ Connexion réussie. Onglets disponibles :")
for ws in worksheets:
    print("-", ws.title)

    # Récupérer l'onglet UC-Usages
sheet = spreadsheet.worksheet("UC-Usages")

# Exemple de ligne à ajouter
row = [
    "SEBASTIEN",           # Code_Individu
    "Réel",                # Type_Temps
    "2025",                # Valeur_Temps
    "2025-05-09",          # Date_Enregistrement
    "Déplacement",         # Type_Categorie
    "Train",               # Sous_Categorie
    "Nantes → Paris (A/R)",# Nom_Usage
    1,                     # Quantite
    "A/R",                 # Unite
    1.6,                   # Facteur_Emission
    1.6                    # Emission_Calculee
]

# Ajouter la ligne à la fin de l'onglet
sheet.append_row(row)
print("✅ Ligne ajoutée à UC-Usages.")