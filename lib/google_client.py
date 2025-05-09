import gspread
from oauth2client.service_account import ServiceAccountCredentials

def get_client():
    scope = [
        "https://spreadsheets.google.com/feeds",
        "https://www.googleapis.com/auth/drive"
    ]
    key_path = "/etc/secrets/greenway_459306.json"
    creds = ServiceAccountCredentials.from_json_keyfile_name(key_path, scope)
    return gspread.authorize(creds)

def get_worksheet(sheet_name):
    client = get_client()
    sheet = client.open(sheet_name).sheet1
    return sheet