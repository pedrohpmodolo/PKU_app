from flask import Flask, request, jsonify
from flask_cors import CORS
from API_nutrition_analysis import analyze_ingredients, ALL_DATA_TYPES
from llm import generate_pku_safe_recipe_with_rag

app = Flask(__name__)
CORS(app)

# Global variables to track daily PHE intake and meals
daily_phe_total = 0
daily_meals = []

@app.route("/analyze-preview", methods=["POST"])
def analyze_preview():
    """Analyze ingredients without adding to daily tracking"""
    data = request.get_json()
    ingredients = data.get("ingredients", [])
    meal_type = data.get("meal_type", "Unspecified")

    if not ingredients:
        return jsonify({"error": "No ingredients provided"}), 400

    # Use both SR Legacy and Survey (FNDDS) for best coverage
    selected_types = ALL_DATA_TYPES["3"]

    # Step 1: Analyze ingredients
    safe_ingredients, total_phe, nutrition_summary = analyze_ingredients(ingredients, selected_types)

    # Step 2: Generate recipe using LLM
    result = generate_pku_safe_recipe_with_rag(safe_ingredients, nutrition_summary)

    # Step 3: Return result WITHOUT adding to daily tracking
    return jsonify({
        "recipe": result["recipe"],
        "extra_ingredients": result["extra_ingredients"],
        "nutrition_summary": nutrition_summary,
        "total_phe": total_phe
    })

@app.route("/analyze", methods=["POST"])
def analyze():
    global daily_phe_total, daily_meals
    
    data = request.get_json()
    ingredients = data.get("ingredients", [])
    meal_type = data.get("meal_type", "Unspecified")

    if not ingredients:
        return jsonify({"error": "No ingredients provided"}), 400

    # Use both SR Legacy and Survey (FNDDS) for best coverage
    selected_types = ALL_DATA_TYPES["3"]

    # Step 1: Analyze ingredients
    safe_ingredients, total_phe, nutrition_summary = analyze_ingredients(ingredients, selected_types)

    # Step 2: Generate recipe using LLM
    result = generate_pku_safe_recipe_with_rag(safe_ingredients, nutrition_summary)

    # Step 3: Add to daily tracking
    meal_data = {
        "meal_type": meal_type,
        "ingredients": ingredients,
        "phe_amount": total_phe,
        "nutrition_summary": nutrition_summary,
        "recipe": result["recipe"]
    }
    daily_meals.append(meal_data)
    daily_phe_total += total_phe

    # Step 4: Return full result with daily tracking
    return jsonify({
        "recipe": result["recipe"],
        "extra_ingredients": result["extra_ingredients"],
        "nutrition_summary": nutrition_summary,
        "total_phe": total_phe,
        "daily_phe_total": daily_phe_total,
        "daily_meals": daily_meals
    })

@app.route("/daily-summary", methods=["GET"])
def get_daily_summary():
    """Get current daily PHE total and meals"""
    return jsonify({
        "daily_phe_total": daily_phe_total,
        "daily_meals": daily_meals,
        "meals_count": len(daily_meals)
    })

@app.route("/reset-day", methods=["POST"])
def reset_daily_tracking():
    """Reset daily PHE tracking for a new day"""
    global daily_phe_total, daily_meals
    daily_phe_total = 0
    daily_meals = []
    return jsonify({
        "message": "Daily tracking reset successfully",
        "daily_phe_total": daily_phe_total,
        "daily_meals": daily_meals
    })

if __name__ == "__main__":
    app.run(debug=True)
