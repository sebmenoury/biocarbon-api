from flask import Blueprint, request, jsonify
from google_client import get_worksheet
from core.constants.const import UC_USAGES_SHEET
import datetime
import uuid

bp_uc_usages = Blueprint("uc_usages", __name__)

@bp_uc_usages.route("/api/uc/usages", methods=["POST"])
def add_usage():
    data = request.get_json()

    required_fields = [
        "Code_Individu", "Type_Temps", "Valeur_Temps", "Date_Enregistrement",
        "Type_Categorie", "Sous_Categorie", "Nom_Usage", "Quantite",
        "Distance_km", "Unite", "Facteur_Emission", "Emission_Calculee"
    ]

    if not all(field in data for field in required_fields):
        return jsonify({"error": "Champs manquants dans la requête"}), 400

    # Génère un identifiant usage unique
    timestamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    id_usage = f"{data['Code_Individu']}-{data['Type_Temps']}-{data['Valeur_Temps']}-{data['Nom_Usage'].replace(' ', '_')[:20]}-{timestamp}"

    sheet = get_worksheet(UC_USAGES_SHEET)
    sheet.append_row([
        id_usage,
        data["Code_Individu"],
        data["Type_Temps"],
        data["Valeur_Temps"],
        data["Date_Enregistrement"],
        data["Type_Categorie"],
        data["Sous_Categorie"],
        data["Nom_Usage"],
        data["Quantite"],
        data["Distance_km"],
        data["Unite"],
        data["Facteur_Emission"],
        data["Emission_Calculee"]
    ])

    return jsonify({"message": "Usage ajouté avec succès ✅", "ID_Usage": id_usage}), 201
