import sqlite3
import os
DB_PATH = os.path.join(os.path.dirname(__file__), "../foods.db")

# Constants for PHE levels
# These values are based on typical dietary recommendations for PKU patients.
ADULT_MIN_PHE = 250
ADULT_MAX_PHE = 500


def get_food_info(food_name):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("SELECT * FROM foods WHERE LOWER([Food Item]) = LOWER(?)", (food_name,))
    result = c.fetchone()
    conn.close()
    return result

def classify_phe(phe_value):
    """Classify PHE amount into Safe, Caution, or Avoid levels."""
    if phe_value < 50:
        return "Safe"
    elif phe_value <= 100:
        return "Caution"
    else:
        return "Avoid"
def clean_phe_value(raw_phe):
    if not raw_phe:
        return 0.0
    # Remove anything in parentheses
    raw_phe = raw_phe.split("(")[0]
    raw_phe = raw_phe.strip()
    try:
        return float(raw_phe)
    except ValueError:
        return 0.0
    
def analyze_ingredients(ingredient_list):
    total_phe = 0
    print("\n=== PKU Nutrition Analysis Results ===")
    
    for item in ingredient_list:
        info = get_food_info(item)
        if info:
            phe = clean_phe_value(info[3])
            total_phe += phe
            flag = classify_phe(phe)
            print(f"{item}: {phe} mg PHE → {flag}")
        else:
            print(f"{item}: Not found in database")
    
    print("\n--- Meal Summary ---")
    print(f"Total PHE in meal: {total_phe} mg")

    # Evaluation for Adults
    if total_phe < ADULT_MIN_PHE:
        print(f"⚠️ For adults: Below typical recommended range ({ADULT_MIN_PHE}–{ADULT_MAX_PHE} mg/day).")
    elif total_phe > ADULT_MAX_PHE:
        print(f"⚠️ For adults: Above typical recommended range ({ADULT_MIN_PHE}–{ADULT_MAX_PHE} mg/day).")
    else:
        print(f"✅ For adults: Within typical recommended range ({ADULT_MIN_PHE}–{ADULT_MAX_PHE} mg/day).")


def analyze_meal(meal):
    print(f"Analyzing meal: {meal['name']}")
    ingredients = meal.get('ingredients', [])
    analyze_ingredients(ingredients)
    print("Analysis complete.")

if __name__ == "__main__":
    user_input = input("Enter ingredients separated by commas: ")
    if user_input.strip() == "":
        print("No ingredients entered. Exiting.")
    else:
        ingredients = [item.strip() for item in user_input.split(",")]
        analyze_ingredients(ingredients)

