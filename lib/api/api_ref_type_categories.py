from flask import Blueprint, jsonify
from lib.google_client import get_worksheet
from lib.core.constants.const_api import SHEET_NAME, REF_TYPE_CATEGORIES_SHEET

bp_ref_type_categories = Blueprint("ref_type_categorie", __name__)

@bp_ref_type_categories.route("/api/ref/type_categorie", methods=["GET"])
def get_ref_usages():
    try:
        sheet = get_worksheet(SHEET_NAME, REF_TYPE_CATEGORIES_SHEET)
        records = sheet.get_all_records()
        return jsonify(records)
    except Exception as e:
        return jsonify({"error": str(e)}), 500