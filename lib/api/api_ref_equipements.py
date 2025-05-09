from flask import Blueprint, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, REF_EQUIPEMENTS_SHEET

bp_ref_equipements = Blueprint("ref_equipements", __name__)

@bp_ref_equipements.route("/api/ref/equipements", methods=["GET"])
def get_ref_equipements():
    try:
        sheet = get_worksheet(SHEET_NAME, REF_EQUIPEMENTS_SHEET)
        records = sheet.get_all_records()
        return jsonify(records)
    except Exception as e:
        return jsonify({"error": str(e)}), 500