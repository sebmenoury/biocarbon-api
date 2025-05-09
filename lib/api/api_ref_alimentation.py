from flask import Blueprint, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, REF_ALIMENTATION_SHEET

bp_ref_usages = Blueprint("ref_usages", __name__)

@bp_ref_usages.route("/api/ref/usages", methods=["GET"])
def get_ref_usages():
    try:
        sheet = get_worksheet(SHEET_NAME, REF_ALIMENTATION_SHEET)
        records = sheet.get_all_records()
        return jsonify(records)
    except Exception as e:
        return jsonify({"error": str(e)}), 500