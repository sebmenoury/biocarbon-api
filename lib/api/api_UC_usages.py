from flask import Blueprint, request, jsonify
from google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, UC_USAGES_SHEET
import datetime
import uuid

bp_uc_usages = Blueprint("uc_usages", __name__)

@bp_uc_usages.route("/api/uc/usages", methods=["POST"])
def add_usage():
    data = request.get_json()

    required_fields = [
        "Code_Individu", "Type_Temps", "Valeur_Temps", "Date_Enregistrement",
        "Type_Categorie", "Sous_Categorie", "Nom_Usage", "Quantite",
        "Distance_km", "Unite", "Facteur_Emission", "Emission_Calculee", "Type_Objet"
    ]

    if not all(field in data for field in required_fields):
        return jsonify({"error": "Champs manquants dans la requête"}), 400

    # Génère un identifiant usage unique
    timestamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    id_usage = f"{data['Code_Individu']}-{data['Type_Temps']}-{data['Valeur_Temps']}-{data['Nom_Usage'].replace(' ', '_')[:20]}-{timestamp}"

    sheet = get_worksheet(SHEET_NAME, UC_USAGES_SHEET)
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
        data["Emission_Calculee"],
        data["Type_Objet"],
    ])

    return jsonify({"message": "Usage ajouté avec succès ✅", "ID_Usage": id_usage}), 201


@bp_uc_usages.route("/api/uc/usages", methods=["GET"])
def get_usages():
    sheet = get_worksheet(SHEET_NAME, UC_USAGES_SHEET)
    rows = sheet.get_all_records()

    # Filtrage optionnel par individu, année ou type
    code = request.args.get("code_individu")
    annee = request.args.get("valeur_temps")
    type_temps = request.args.get("type_temps")

    if code:
        rows = [r for r in rows if r["Code_Individu"] == code]
    if annee:
        rows = [r for r in rows if str(r["Valeur_Temps"]) == str(annee)]
    if type_temps:
        rows = [r for r in rows if r["Type_Temps"] == type_temps]

    return jsonify(rows)

@bp_uc_usages.route("/api/uc/usages/<id_usage>", methods=["PATCH"])
def update_usage(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_USAGES_SHEET)
    records = sheet.get_all_records()
    data = request.get_json()

    # Recherche de la ligne à mettre à jour
    for idx, row in enumerate(records, start=2):  # +2 pour ignorer en-tête
        if row["ID_Usage"] == id_usage:
            for key, value in data.items():
                if key in row:
                    sheet.update_cell(idx, list(row.keys()).index(key) + 1, value)
            return jsonify({"message": f"Usage {id_usage} mis à jour ✅"})
    
    return jsonify({"error": f"Usage {id_usage} non trouvé"}), 404

@bp_uc_usages.route("/api/uc/usages/<id_usage>", methods=["DELETE"])
def delete_usage(id_usage):
    try:
        sheet = get_worksheet(SHEET_NAME, UC_USAGES_SHEET)
        records = sheet.get_all_records()

        for idx, row in enumerate(records, start=2):  # start=2 pour ignorer l'entête
            if row.get("ID_Usage") == id_usage:
                sheet.delete_rows(idx)
                return jsonify({"message": f"Usage {id_usage} supprimé ✅"})

        return jsonify({"error": f"Usage {id_usage} non trouvé"}), 404

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500
