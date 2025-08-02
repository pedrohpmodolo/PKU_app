from flask import Flask, request, jsonify
from backend.API_nutrition_analysis import analyze_ingredients
from backend.llm import generate_pku_safe_recipe_with_rag

app = Flask(__name__)
daily_phe_total = 0

# Define which USDA data types to use for lookups
SELECTED_TYPES = ["SR Legacy", "Survey (FNDDS)"]

@app.route("/", methods=["GET"])
def home():
    """
    Health check route.
    """
    return jsonify({
         "message": "🌸 Welcome to PKU Kitchen! 🌸",
         "routes": ["/analyze (POST)", "/generate-recipe (POST)", "/reset (POST)"]
    })

@app.route("/analyze", methods=["POST"])
def analyze():
    """
    Analyze endpoint.
    Expects JSON:
    {
        "ingredients": ["spinach", "rice", "cheddar"]
    }
    Returns:
    {
        "safeIngredients": [...],
        "mealPhe": float,
        "nutritionSummary": [...],
        "dailyPheTotal": float
    }
    """
    global daily_phe_total
    data = request.get_json()

    if not data or "ingredients" not in data:
        return jsonify({"error": "Missing 'ingredients' in request body"}), 400

    ingredients = data["ingredients"]
    if not isinstance(ingredients, list) or not all(isinstance(i, str) for i in ingredients):
        return jsonify({"error": "'ingredients' must be a list of strings"}), 400

    # Call your USDA analysis pipeline
    safe_ingredients, meal_phe, nutrition_summary = analyze_ingredients(ingredients, SELECTED_TYPES)

    daily_phe_total += meal_phe

    response = {
        "safeIngredients": safe_ingredients,
        "mealPhe": meal_phe,
        "nutritionSummary": nutrition_summary,
        "dailyPheTotal": daily_phe_total
    }
    print(f"[ANALYZE] Ingredients: {ingredients} | Meal PHE: {meal_phe} | Running Total: {daily_phe_total}")
    return jsonify(response)


@app.route("/generate-recipe", methods=["POST"])
def generate_recipe():
    """
    Recipe generation endpoint.
    Expects JSON:
    {
        "ingredients": [...],
        "nutritionSummary": [...]
    }
    Returns:
    {
        "recipe": "..."
    }
    """
    data = request.get_json()

    ingredients = data.get("ingredients")
    nutrition_summary = data.get("nutritionSummary")

    if not ingredients or not nutrition_summary:
        return jsonify({"error": "Missing 'ingredients' or 'nutritionSummary'"}), 400

    if not isinstance(ingredients, list) or not all(isinstance(i, str) for i in ingredients):
        return jsonify({"error": "'ingredients' must be a list of strings"}), 400

    if not isinstance(nutrition_summary, list):
        return jsonify({"error": "'nutritionSummary' must be a list of nutrition objects"}), 400

    # Call LLM with RAG-enhanced prompt
    result = generate_pku_safe_recipe_with_rag(ingredients, nutrition_summary)
    return jsonify(result)

@app.route("/reset", methods=["POST"])
def reset():
    """
    Resets the daily PHE counter.
    Returns:
    {
        "message": "Daily PHE total reset."
    }
    """
    global daily_phe_total
    daily_phe_total = 0
    print("[RESET] Daily PHE total counter reset.")
    return jsonify({"message": "Daily PHE total reset."})


if __name__ == "__main__":
    app.run(debug=True)
