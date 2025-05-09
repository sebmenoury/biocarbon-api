from flask import Blueprint, jsonify
from google_client import get_worksheet
from lib.core.constants.const import REF_USAGES_SHEET  # ✅ Corrigé

bp_ref_usages = Blueprint("ref_usages", __name__)

@bp_ref_usages.route("/api/ref/usages", methods=["GET"])
def get_ref_usages():
    sheet = get_worksheet(REF_USAGES_SHEET)
    records = sheet.get_all_records()
    return jsonify(records)