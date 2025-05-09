from flask import Blueprint, request, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, UC_INDIVIDU_SHEET
import datetime

bp_uc_individu = Blueprint("uc_individu", __name__)

@bp_uc_individu.route("/api/uc/individus", methods=["POST"])
def add_individu():
    data = request.get_json()

    required_fields = ["Code_Individu", "Nom", "Prenom", "Mail", "Mot de passe"]

    if not all(field in data for field in required_fields):
        return jsonify({"error": "Champs manquants dans la requête"}), 400

    timestamp = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")
    id_usage = f"{data['Code_Individu']}-Individu-{timestamp}"

    sheet = get_worksheet(SHEET_NAME, UC_INDIVIDU_SHEET)
    sheet.append_row([
        id_usage,
        data["Code_Individu"],
        data["Nom"],
        data["Prenom"],
        data["Mail"],
        data["Mot de passe"]
    ])

    return jsonify({"message": "Individu ajouté avec succès ✅", "ID_Usage": id_usage}), 201

@bp_uc_individu.route("/api/uc/individus", methods=["GET"])
def get_individus():
    sheet = get_worksheet(SHEET_NAME, UC_INDIVIDU_SHEET)
    rows = sheet.get_all_records()

    code = request.args.get("code_individu")
    mail = request.args.get("mail")

    if code:
        rows = [r for r in rows if r["Code_Individu"] == code]
    if mail:
        rows = [r for r in rows if r["Mail"] == mail]

    return jsonify(rows)

@bp_uc_individu.route("/api/uc/individus/<id_usage>", methods=["PATCH"])
def update_individu(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_INDIVIDU_SHEET)
    records = sheet.get_all_records()
    data = request.get_json()

    for idx, row in enumerate(records, start=2):
        if row["ID_Usage"] == id_usage:
            for key, value in data.items():
                if key in row:
                    sheet.update_cell(idx, list(row.keys()).index(key) + 1, value)
            return jsonify({"message": f"Individu {id_usage} mis à jour ✅"})

    return jsonify({"error": f"Individu {id_usage} non trouvé"}), 404

@bp_uc_individu.route("/api/uc/individus/<id_usage>", methods=["DELETE"])
def delete_individu(id_usage):
    try:
        sheet = get_worksheet(SHEET_NAME, UC_INDIVIDU_SHEET)
        records = sheet.get_all_records()

        for idx, row in enumerate(records, start=2):
            if row.get("ID_Usage") == id_usage:
                sheet.delete_rows(idx)
                return jsonify({"message": f"Individu {id_usage} supprimé ✅"})

        return jsonify({"error": f"Individu {id_usage} non trouvé"}), 404

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500
