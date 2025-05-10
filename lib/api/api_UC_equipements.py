from flask import Blueprint, request, jsonify
from google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, UC_EQUIPEMENTS_SHEET
import datetime
import uuid

bp_uc_equipements = Blueprint("uc_equipements", __name__)

@bp_uc_equipements.route("/api/uc/equipements", methods=["POST"])
def add_equipement():
    data = request.get_json()

    required_fields = [
        "Code_Individu", "Type_Temps", "Valeur_Temps", "Date_Enregistrement",
        "Type_Categorie", "Sous_Categorie", "Nom_Objet", "Quantite", "Unite",
        "Emission_Estimee", "Type_Objet", "Annee_Achat", "Duree_Amortissement"
    ]

    if not all(field in data for field in required_fields):
        return jsonify({"error": "Champs manquants dans la requête"}), 400

    # Génère un identifiant usage unique
    timestamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    id_usage = f"{data['Code_Individu']}-{data['Type_Temps']}-{data['Valeur_Temps']}-{data['Nom_Objet'].replace(' ', '_')[:20]}-{timestamp}"

    sheet = get_worksheet(SHEET_NAME, UC_EQUIPEMENTS_SHEET)
    sheet.append_row([
        id_usage,
        data["Code_Individu"],
        data["Type_Temps"],
        data["Valeur_Temps"],
        data["Date_Enregistrement"],
        data["Type_Categorie"],
        data["Sous_Categorie"],
        data["Nom_Objet"],
        data["Quantite"],
        data["Unite"],
        data["Emission_Estimee"],
        data["Type_Objet"],
        data["Annee_Achat"],
        data["Duree_Amortissement"]
    ])

    return jsonify({"message": "Équipement ajouté avec succès ✅", "ID_Usage": id_usage}), 201

@bp_uc_equipements.route("/api/uc/equipements", methods=["GET"])
def get_equipements():
    sheet = get_worksheet(SHEET_NAME, UC_EQUIPEMENTS_SHEET)
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

@bp_uc_equipements.route("/api/uc/equipements/<id_usage>", methods=["PATCH"])
def update_equipement(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_EQUIPEMENTS_SHEET)
    records = sheet.get_all_records()
    data = request.get_json()

    for idx, row in enumerate(records, start=2):
        if row["ID_Usage"] == id_usage:
            for key, value in data.items():
                if key in row:
                    sheet.update_cell(idx, list(row.keys()).index(key) + 1, value)
            return jsonify({"message": f"Équipement {id_usage} mis à jour ✅"})

    return jsonify({"error": f"Équipement {id_usage} non trouvé"}), 404

@bp_uc_equipements.route("/api/uc/equipements/<id_usage>", methods=["DELETE"])
def delete_equipement(id_usage):
    try:
        sheet = get_worksheet(SHEET_NAME, UC_EQUIPEMENTS_SHEET)
        records = sheet.get_all_records()

        for idx, row in enumerate(records, start=2):
            if row.get("ID_Usage") == id_usage:
                sheet.delete_rows(idx)
                return jsonify({"message": f"Équipement {id_usage} supprimé ✅"})

        return jsonify({"error": f"Équipement {id_usage} non trouvé"}), 404

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500
