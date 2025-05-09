from flask import Blueprint, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, REF_ALIMENTATION_SHEET

bp_ref_alimentation = Blueprint("ref_alimentation", __name__)

@bp_ref_alimentation.route("/api/ref/alimentation", methods=["GET"])
def get_ref_alimentation():
    try:
        sheet = get_worksheet(SHEET_NAME, REF_ALIMENTATION_SHEET)
        records = sheet.get_all_records()
        return jsonify(records)
    except Exception as e:
        return jsonify({"error": str(e)}), 500