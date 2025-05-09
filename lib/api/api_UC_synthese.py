from flask import Blueprint, request, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, UC_SYNTHESE_SHEET
import datetime

bp_uc_synthese = Blueprint("uc_synthese", __name__)

@bp_uc_synthese.route("/api/uc/synthese", methods=["POST"])
def add_synthese():
    data = request.get_json()

    required_fields = [
        "Code_Individu", "Type_Temps", "Valeur_Temps",
        "Type_Categorie", "Sous_Categorie",
        "Emission_Aggregée", "Nb_Enregistrements", "Date_Calcul"
    ]

    if not all(field in data for field in required_fields):
        return jsonify({"error": "Champs manquants dans la requête"}), 400

    timestamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    id_usage = f"{data['Code_Individu']}-{data['Type_Temps']}-{data['Valeur_Temps']}-{data['Sous_Categorie'].replace(' ', '_')[:20]}-{timestamp}"

    sheet = get_worksheet(SHEET_NAME, UC_SYNTHESE_SHEET)
    sheet.append_row([
        id_usage,
        data["Code_Individu"],
        data["Type_Temps"],
        data["Valeur_Temps"],
        data["Type_Categorie"],
        data["Sous_Categorie"],
        data["Emission_Aggregée"],
        data["Nb_Enregistrements"],
        data["Date_Calcul"]
    ])

    return jsonify({"message": "Synthèse ajoutée avec succès ✅", "ID_Usage": id_usage}), 201

@bp_uc_synthese.route("/api/uc/synthese", methods=["GET"])
def get_synthese():
    sheet = get_worksheet(SHEET_NAME, UC_SYNTHESE_SHEET)
    rows = sheet.get_all_records()

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

@bp_uc_synthese.route("/api/uc/synthese/<id_usage>", methods=["PATCH"])
def update_synthese(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_SYNTHESE_SHEET)
    records = sheet.get_all_records()
    data = request.get_json()

    for idx, row in enumerate(records, start=2):
        if row["ID_Usage"] == id_usage:
            for key, value in data.items():
                if key in row:
                    sheet.update_cell(idx, list(row.keys()).index(key) + 1, value)
            return jsonify({"message": f"Synthèse {id_usage} mise à jour ✅"})

    return jsonify({"error": f"Synthèse {id_usage} non trouvée"}), 404

@bp_uc_synthese.route("/api/uc/synthese/<id_usage>", methods=["DELETE"])
def delete_synthese(id_usage):
    try:
        sheet = get_worksheet(SHEET_NAME, UC_SYNTHESE_SHEET)
        records = sheet.get_all_records()

        for idx, row in enumerate(records, start=2):
            if row.get("ID_Usage") == id_usage:
                sheet.delete_rows(idx)
                return jsonify({"message": f"Synthèse {id_usage} supprimée ✅"})

        return jsonify({"error": f"Synthèse {id_usage} non trouvée"}), 404

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500
