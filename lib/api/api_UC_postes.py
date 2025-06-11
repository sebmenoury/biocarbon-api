from flask import Blueprint, request, jsonify
from google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, UC_POSTES_SHEET
import datetime
import uuid

bp_uc_postes = Blueprint("uc_postes", __name__)

@bp_uc_postes.route("/api/uc/postes", methods=["POST"])
def add_poste():
    data = request.get_json()

    required_fields = [
        "ID_Usage",  # <<< on attend que Flutter fournisse l'ID
        "Code_Individu", "Type_Temps", "Valeur_Temps", "Date_Enregistrement",
        "ID_Bien", "Type_Bien", "Type_Poste", "Type_Categorie", "Sous_Categorie",
        "Nom_Poste", "Nom_Logement", "Quantite", "Unite", "Frequence",
        "Facteur_Emission", "Emission_Calculee", "Mode_Calcul",
        "Annee_Achat", "Duree_Amortissement"
    ]

    # Vérifie que tous les champs sont bien présents
    if not all(field in data and data[field] != "" for field in required_fields):
        return jsonify({"error": "Champs manquants ou vides dans la requête"}), 400

    try:
        sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
        sheet.append_row([
            data["ID_Usage"],
            data["Code_Individu"],
            data["Type_Temps"],
            data["Valeur_Temps"],
            data["Date_Enregistrement"],
            data["ID_Bien"],
            data["Type_Bien"],
            data["Type_Poste"],
            data["Type_Categorie"],
            data["Sous_Categorie"],
            data["Nom_Poste"],
            data["Nom_Logement"],
            data["Quantite"],
            data["Unite"],
            data["Frequence"],
            data["Facteur_Emission"],
            data["Emission_Calculee"],
            data["Mode_Calcul"],
            data["Annee_Achat"],
            data["Duree_Amortissement"]
        ])
        return jsonify({"ID_Usage": data["ID_Usage"], "message": "Poste ajouté avec succès ✅"}), 201

    except Exception as e:
        return jsonify({"error": f"Erreur d'enregistrement : {str(e)}"}), 500


@bp_uc_postes.route("/api/uc/postes", methods=["GET"])
def get_postes():
    sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
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

@bp_uc_postes.route("/api/uc/postes/<id_usage>", methods=["PATCH"])
def update_postes(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
    records = sheet.get_all_records()
    data = request.get_json()

    for idx, row in enumerate(records, start=2):
        if row["ID_Usage"] == id_usage:
            for key, value in data.items():
                if key in row:
                    sheet.update_cell(idx, list(row.keys()).index(key) + 1, value)
            return jsonify({"message": f"Poste {id_usage} mis à jour ✅"})

    return jsonify({"error": f"Poste {id_usage} non trouvé"}), 404

@bp_uc_postes.route("/api/uc/postes/<id_usage>", methods=["DELETE"])
def delete_postes(id_usage):
    try:
        sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
        records = sheet.get_all_records()

        for idx, row in enumerate(records, start=2):
            if row.get("ID_Usage") == id_usage:
                sheet.delete_rows(idx)
                return jsonify({"message": f"Poste {id_usage} supprimé ✅"})

        return jsonify({"error": f"Poste {id_usage} non trouvé"}), 404

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500
