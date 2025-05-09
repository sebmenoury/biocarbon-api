print("✅ DÉMARRAGE APP.PY")

import sys, os
sys.path.append(os.path.abspath("lib"))

from flask import Flask
from api.api_ref_usages import bp_ref_usages

app = Flask(__name__)
app.register_blueprint(bp_ref_usages)

# ✅ Route simple pour test à la racine
@app.route("/")
def home():
    return "✅ API Biocarbon est en ligne !"

print("✅ ROUTES DISPONIBLES :")
print(app.url_map)

if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))