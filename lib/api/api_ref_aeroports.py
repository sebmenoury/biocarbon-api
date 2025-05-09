from flask import Blueprint, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, REF_AEROPORTS_SHEET

bp_ref_aeroports = Blueprint("ref_aeroports", __name__)

@bp_ref_aeroports.route("/api/ref/aeroports", methods=["GET"])
def get_ref_aeroports():
    try:
        sheet = get_worksheet(SHEET_NAME, REF_AEROPORTS_SHEET)
        records = sheet.get_all_records()
        return jsonify(records)
    except Exception as e:
        return jsonify({"error": str(e)}), 500