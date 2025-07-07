from flask import Blueprint, request, jsonify
from google_client import get_worksheet
from sheets_service import sheet_uc_postes
from flask import Blueprint, request, jsonify
from lib.core.constants.const_api import SHEET_NAME, UC_POSTES_SHEET
import datetime
import uuid

bp_uc_postes = Blueprint("uc_postes", __name__)

@bp_uc_postes.route("/api/uc/postes", methods=["POST"])
def add_poste():
    data = request.get_json()

    required_fields = [
        "ID_Usage", "Code_Individu", "Type_Temps", "Valeur_Temps", "Date_enregistrement",
        "ID_Bien", "Type_Bien", "Type_Poste", "Type_Categorie", "Sous_Categorie",
        "Nom_Poste", "Nom_Logement", "Quantite", "Unite", "Frequence", "Nb_Personne",
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
            data.get("Nb_Personne", 1),  # Valeur par défaut si non fourni
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

    idUsage = request.args.get("ID_Usage")  
    individu = request.args.get("Code_Individu")
    annee = request.args.get("Valeur_Temps")
    type_temps = request.args.get("Type_temps")
    id_bien = request.args.get("ID_Bien")  
    sous_categorie = request.args.get('Sous_Categorie')
    type_categorie = request.args.get('Type_Categorie')

    if idUsage:
        rows = [r for r in rows if str(r["ID_Usage"]) == str(idUsage)]
    if individu:
        rows = [r for r in rows if r["Code_Individu"] == individu]
    if annee:
        rows = [r for r in rows if str(r["Valeur_Temps"]) == str(annee)]
    if type_temps:
        rows = [r for r in rows if r["Type_Temps"] == type_temps]
    if id_bien:
        rows = [r for r in rows if str(r["ID_Bien"]) == str(id_bien)]  
    if sous_categorie:
        rows = [d for d in rows if d['Sous_Categorie'] == sous_categorie]
    if type_categorie:
        rows = [d for d in rows if d['Type_Categorie'] == type_categorie]

    return jsonify(rows)


@bp_uc_postes.route("/api/uc/postes/<string:id_usage>", methods=["GET"])
def get_poste_by_id(id_usage):
    sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
    rows = sheet.get_all_records()

    for row in rows:
        if row["ID_Usage"] == id_usage:
            return jsonify(row), 200

    return jsonify({"error": f"Poste {id_usage} non trouvé"}), 404

@bp_uc_postes.route("/api/uc/postes/bulk", methods=["POST", "OPTIONS"])
def save_postes_bulk():
    # ✅ Gérer la requête préflight CORS
    if request.method == 'OPTIONS':
        return '', 200

    try:
        data = request.get_json()
        for poste in data:
            # Valider les champs ici si tu veux
            sheet_uc_postes.append_row([
                poste["ID_Usage"],
                poste["Code_Individu"],
                poste["Type_Temps"],
                poste["Valeur_Temps"],
                poste["Date_enregistrement"],
                poste.get("ID_Bien", ""),
                poste.get("Type_Bien", ""),
                poste["Type_Poste"],
                poste["Type_Categorie"],
                poste["Sous_Categorie"],
                poste["Nom_Poste"],
                poste.get("Nom_Logement", ""),
                poste["Quantite"],
                poste.get("Unite", "unité"),
                poste.get("Frequence", ""),
                poste.get("Nb_Personne", 1),  # Valeur par défaut si non fourni
                poste["Facteur_Emission"],
                poste["Emission_Calculee"],
                poste["Mode_Calcul"],
                poste["Annee_Achat"],
                poste["Duree_Amortissement"],
            ])
        return jsonify({"message": "Postes enregistrés"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


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
                    data.get("Nb_Personne", 1),  # Valeur par défaut si non fourni
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
    
@bp_uc_postes.route('/delete_all', methods=['DELETE', 'OPTIONS'])
def delete_all_postes():
    # ✅ On gère la pré-requête OPTIONS
    if request.method == 'OPTIONS':
        return '', 200

    code_individu = request.args.get('Code_Individu')
    id_bien = request.args.get('ID_Bien')
    valeur_temps = request.args.get('Valeur_Temps')
    sous_categorie = request.args.get('Sous_Categorie')

    if not all([code_individu, id_bien, valeur_temps, sous_categorie]):
        return jsonify({"error": "Paramètres manquants"}), 400

    try:
        sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
        records = sheet.get_all_records()

        rows_to_delete = []
        for idx, row in enumerate(records, start=2):
            if (
                str(row.get('Code_Individu')) == str(code_individu) and
                str(row.get('ID_Bien')) == str(id_bien) and
                str(row.get('Valeur_Temps')) == str(valeur_temps) and
                str(row.get('Sous_Categorie')) == str(sous_categorie)
            ):
                rows_to_delete.append(idx)

        for row_num in reversed(rows_to_delete):
            sheet.delete_rows(row_num)

        return jsonify({"message": f"{len(rows_to_delete)} postes supprimés ✅"}), 200

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500
    
@bp_uc_postes.route('/delete_all_sans_bien', methods=['DELETE', 'OPTIONS'])
def delete_all_postes_sans_bien():
    if request.method == 'OPTIONS':
        return '', 200

    code_individu = request.args.get('Code_Individu')
    valeur_temps = request.args.get('Valeur_Temps')
    type_categorie = request.args.get('Type_Categorie')

    if not all([code_individu, valeur_temps, type_categorie]):
        return jsonify({"error": "Paramètres manquants"}), 400

    try:
        sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
        records = sheet.get_all_records()

        rows_to_delete = []
        for idx, row in enumerate(records, start=2):
            if (
                str(row.get('Code_Individu')) == str(code_individu) and
                str(row.get('Valeur_Temps')) == str(valeur_temps) and
                str(row.get('Type_Categorie')) == str(type_categorie)
            ):
                rows_to_delete.append(idx)

        for row_num in reversed(rows_to_delete):
            sheet.delete_rows(row_num)

        return jsonify({"message": f"{len(rows_to_delete)} postes supprimés ✅"}), 200

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500


@bp_uc_postes.route('/delete_all_sans_bien_sc', methods=['DELETE', 'OPTIONS'])
def delete_all_postes_sans_bien_sc():
    if request.method == 'OPTIONS':
        return '', 200

    code_individu = request.args.get('Code_Individu')
    valeur_temps = request.args.get('Valeur_Temps')
    sous_categorie = request.args.get('Sous_Categorie')

    if not all([code_individu, valeur_temps, sous_categorie]):
        return jsonify({"error": "Paramètres manquants"}), 400

    try:
        sheet = get_worksheet(SHEET_NAME, UC_POSTES_SHEET)
        records = sheet.get_all_records()

        rows_to_delete = []
        for idx, row in enumerate(records, start=2):
            if (
                str(row.get('Code_Individu')) == str(code_individu) and
                str(row.get('Valeur_Temps')) == str(valeur_temps) and
                str(row.get('Sous_Categorie')) == str(sous_categorie)
            ):
                rows_to_delete.append(idx)

        for row_num in reversed(rows_to_delete):
            sheet.delete_rows(row_num)

        return jsonify({"message": f"{len(rows_to_delete)} postes supprimés ✅"}), 200

    except Exception as e:
        return jsonify({"error": f"Erreur serveur : {str(e)}"}), 500