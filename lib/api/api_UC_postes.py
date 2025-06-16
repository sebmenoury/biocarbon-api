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
        "ID_Usage", "Code_Individu", "Type_Temps", "Valeur_Temps", "Date_Enregistrement",
        "ID_Bien", "Type_Bien", "Type_Poste", "Type_Categorie", "Sous_Categorie",
        "Nom_Poste", "Nom_Logement", "Quantite", "Unite", "Frequence",
        "Facteur_Emission", "Emission_Calculee", "Mode_Calcul", "Annee_Achat", "Duree_Amortissement"
    ]

    can_be_empty = ["Valeur_Temps", "ID_Bien", "Type_Bien", "Nom_Logement", "Frequence", "Unite", "Duree_Amortissement"]

    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Champ manquant : {field}"}), 400
        if field not in can_be_empty and str(data[field]).strip() == "":
            return jsonify({"error": f"Champ vide non autorisé : {field}"}), 400

    try:
        sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
        sheet.append_row([
            data["ID_Usage"],
            data["Code_Individu"],
            data["Type_Temps"],
            data["Valeur_Temps"],
            data["Date_enregistrement"],
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
    id_bien = request.args.get("id_bien")  # 🔥 ajout du paramètre

    if code:
        rows = [r for r in rows if r["Code_Individu"] == code]
    if annee:
        rows = [r for r in rows if str(r["Valeur_Temps"]) == str(annee)]
    if type_temps:
        rows = [r for r in rows if r["Type_Temps"] == type_temps]
    if id_bien:
        rows = [r for r in rows if str(r["ID_Bien"]) == str(id_bien)]  # 🔥 filtre par bien

    return jsonify(rows)


@bp_uc_postes.route("/api/uc/postes/<string:id_usage>", methods=["GET"])
def get_poste_by_id(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
    rows = sheet.get_all_records()

    for row in rows:
        if row["ID_Usage"] == id_usage:
            return jsonify(row), 200

    return jsonify({"error": f"Poste {id_usage} non trouvé"}), 404

@bp_uc_postes.route("/api/uc/postes/<string:id_usage>", methods=["PATCH"])
def update_poste(id_usage):
    data = request.get_json()
    sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
    rows = sheet.get_all_values()
    header = rows[0]

    try:
        id_col_index = header.index("ID_Usage")
        for idx, row in enumerate(rows[1:], start=2):  # 2 = ligne 2 (1-based)
            if row[id_col_index] == id_usage:
                updated_row = [  # dans le bon ordre !
                    id_usage,
                    data["Code_Individu"],
                    data["Type_Temps"],
                    data["Valeur_Temps"],
                    data["Date_enregistrement"],
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
                ]
                sheet.update(f"A{idx}:T{idx}", [updated_row])
                return jsonify({"message": f"Poste {id_usage} mis à jour ✅"})
        return jsonify({"error": f"Poste {id_usage} non trouvé"}), 404

    except Exception as e:
        return jsonify({"error": str(e)}), 500

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
