from flask import Blueprint, request, jsonify
from google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, UC_BIENS_IMMOBILIERS_SHEET
import uuid

bp_uc_biens = Blueprint("uc_biens", __name__)

@bp_uc_biens.route("/api/uc/biens", methods=["POST"])
def add_biens():
    data = request.get_json()

    required_fields = ["Code_Individu", "ID_Bien", "Type_Bien", "Nb_Proprietaires", "Nb_Habitants", "Dénomination", "Adresse", "Inclure_dans_bilan"]
    if not all(field in data for field in required_fields):
        return jsonify({"error": "Champs manquants dans la requête"}), 400

    # Générer un UUID si non fourni
    id_bien = data.get("ID_Bien", str(uuid.uuid4()))

    sheet = get_worksheet(SHEET_NAME, UC_BIENS_IMMOBILIERS_SHEET)
    sheet.append_row([
        data["Code_Individu"],
        id_bien,
        data["Type_Bien"],
        data["Nb_Proprietaires"],
        data["Nb_Habitants"],
        data["Dénomination"],
        data["Adresse"],
        data["Inclure_dans_bilan"]
    ])

    return jsonify({"message": "Bien ajouté avec succès ✅", "ID_Bien": id_bien}), 201

@bp_uc_biens.route("/api/uc/biens", methods=["GET"])
def get_biens():
    sheet = get_worksheet(SHEET_NAME, UC_BIENS_IMMOBILIERS_SHEET)
    rows = sheet.get_all_records()
    code = request.args.get("code_individu")

    if code:
        rows = [r for r in rows if r["Code_Individu"] == code]

    return jsonify(rows)

@bp_uc_biens.route("/api/uc/biens/<ID_Bien>", methods=["PATCH"])
def update_biens(ID_Bien):
    sheet = get_worksheet(SHEET_NAME, UC_BIENS_IMMOBILIERS_SHEET)
    records = sheet.get_all_records()
    headers = sheet.row_values(1)
    data = request.get_json()

    for idx, row in enumerate(records, start=2):
        if str(row.get("ID_Bien")) == ID_Bien:
            for key, value in data.items():
                if key in headers:
                    col_idx = headers.index(key) + 1
                    sheet.update_cell(idx, col_idx, value)
            return jsonify({"message": f"Bien {ID_Bien} mis à jour ✅"})

    return jsonify({"error": f"Bien {ID_Bien} non trouvé"}), 404

@bp_uc_biens.route("/api/uc/biens/<ID_Bien>", methods=["DELETE"])
def delete_biens(ID_Bien):
    try:
        sheet = get_worksheet(SHEET_NAME, UC_BIENS_IMMOBILIERS_SHEET)
        records = sheet.get_all_records()

        for idx, row in enumerate(records, start=2):
            if str(row.get("ID_Bien")) == ID_Bien:
                sheet.delete_rows(idx)
                return jsonify({"message": f"Bien {ID_Bien} supprimé ✅"})

        return jsonify({"error": f"Bien {ID_Bien} non trouvé"}), 404

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500