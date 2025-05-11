print("✅ DÉMARRAGE APP.PY")

import sys, os
sys.path.append(os.path.abspath("lib"))

from flask import Flask
from flask_cors import CORS  # ✅ ajout CORS
from lib.api.api_ref_usages import bp_ref_usages
from lib.api.api_ref_alimentation import bp_ref_alimentation
from lib.api.api_ref_aeroports import bp_ref_aeroports
from lib.api.api_ref_equipements import bp_ref_equipements
from lib.api.api_ref_type_categories import bp_ref_type_categories

from lib.api.api_UC_postes import bp_uc_postes
from lib.api.api_UC_individu import bp_uc_individu
from lib.api.api_UC_synthese import bp_uc_synthese


app = Flask(__name__)
CORS(app)  # ✅ active les CORS sur toutes les routes

@app.route("/")
def home():
    return "✅ API Biocarbon en ligne"

# enregistrement du blueprint usages
app.register_blueprint(bp_ref_usages)
app.register_blueprint(bp_ref_alimentation)
app.register_blueprint(bp_ref_aeroports)
app.register_blueprint(bp_ref_equipements)
app.register_blueprint(bp_ref_type_categories)

app.register_blueprint(bp_uc_postes)
app.register_blueprint(bp_uc_individu)
app.register_blueprint(bp_uc_synthese)

if __name__ == "__main__":
    print("✅ ROUTES DISPONIBLES :")
    print(app.url_map)
    app.run(host="0.0.0.0", port=10000)