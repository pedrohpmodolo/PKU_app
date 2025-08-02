import requests
import time

USDA_API_KEY = "hQJDeFSPmou32N5igXmCa1g64XQ45un2xqDukodl"

ALL_DATA_TYPES = {
    "1": ["SR Legacy"],
    "2": ["Survey (FNDDS)"],
    "3": ["SR Legacy", "Survey (FNDDS)"]
}

def choose_data_types():
    """
    Prompt user to choose which USDA data types to search.
    """
    print("\nWhich USDA data types do you want to include in your search?")
    print("1) SR Legacy only")
    print("2) Survey (FNDDS) only")
    print("3) Both SR Legacy and Survey")
    choice = input("Enter 1, 2, or 3 (default is 3): ").strip()
    return ALL_DATA_TYPES.get(choice, ["SR Legacy", "Survey (FNDDS)"])


def search_food_options(query, selected_types, max_pages=3):
    """
    Query the USDA FoodData Central API for food matches.
    Filters results by the selected data types.
    """
    url = "https://api.nal.usda.gov/fdc/v1/foods/search"
    options = []
    page = 1

    while page <= max_pages:
        params = {
            "api_key": USDA_API_KEY,
            "query": query,
            "pageSize": 100,
            "pageNumber": page
        }

        print(f"📡 USDA Request: '{query}' (Page {page})")
        response = requests.get(url, params=params)
        data = response.json()

        foods = data.get("foods", [])
        print(f"🔎 USDA Returned {len(foods)} foods this page")

        for food in foods:
            desc = food.get("description", "")
            dataType = food.get("dataType", "")
            fdcId = food.get("fdcId", "")

            if dataType.lower() not in [t.lower() for t in selected_types]:
                continue

            options.append((fdcId, desc, dataType))

        if options:
            print(f"✅ Matches found on page {page}")
            break

        page += 1
        time.sleep(0.3)  # Avoid hammering the server

    if not options:
        print(f"⚠️ No matches found for '{query}' after {max_pages} pages.")

    return options


def auto_select_best_option(options, item):
    """
    Automatically select the best USDA match for API usage.
    Prioritizes raw/basic forms and SR Legacy data.
    """
    if not options:
        return None
    
    print(f"\n🔍 Auto-selecting best match for '{item}':")
    for idx, (fdcId, desc, dataType) in enumerate(options[:5], 1):  # Show top 5 options
        parts = [desc.title()]
        if dataType:
            parts.append(dataType)
        parts.append(f"FDC ID: {fdcId}")
        print(f"{idx}) {' | '.join(parts)}")
    
    # Scoring system to find best match
    best_score = -1
    best_option = None
    
    for fdcId, desc, dataType in options:
        score = 0
        desc_lower = desc.lower()
        item_lower = item.lower()
        
        # Higher score for exact or close matches
        if item_lower in desc_lower:
            score += 10
        
        # Prefer raw/basic forms
        if any(word in desc_lower for word in ['raw', 'fresh', 'plain']):
            score += 5
        
        # Prefer SR Legacy over Survey data (more standardized)
        if dataType == "SR Legacy":
            score += 3
        
        # Avoid processed/prepared forms
        if any(word in desc_lower for word in ['fried', 'cooked', 'prepared', 'seasoned', 'salted']):
            score -= 2
        
        if score > best_score:
            best_score = score
            best_option = fdcId
    
    if best_option:
        selected_desc = next(desc for fdcId, desc, dataType in options if fdcId == best_option)
        print(f"✅ Auto-selected: {selected_desc.title()}")
    
    return best_option


def get_food_details(fdc_id):
    """
    Retrieve detailed nutrient information for a specific food by FDC ID.
    """
    url = f"https://api.nal.usda.gov/fdc/v1/food/{fdc_id}"
    params = {"api_key": USDA_API_KEY}
    response = requests.get(url, params=params)
    return response.json()


def estimate_phe_from_protein(protein_value):
    """
    Estimate PHE from protein if no direct PHE value is provided.
    Approx: 50mg PHE per gram of protein.
    """
    if protein_value is not None:
        return protein_value * 50
    return None


def extract_phe_or_estimate(data):
    """
    Extract PHE, protein, carbs, energy per 100g from USDA record.
    Estimate PHE from protein if not provided.
    """
    phe_value = None
    protein_value = None
    energy_value = None
    carbs_value = None

    nutrients = data.get("foodNutrients", [])
    if not nutrients:
        print("⚠️ USDA record has no 'foodNutrients' found!")
        return None

    for nutrient in nutrients:
        inner = nutrient.get("nutrient", {})
        name = inner.get("name", "").lower()
        value = nutrient.get("amount", 0.0)

        if "phenylalanine" in name:
            phe_value = value * 1000  # USDA is in grams; we want mg
        elif "protein" in name and protein_value is None:
            protein_value = value
        elif "energy" in name and "kcal" in inner.get("unitName", "").lower():
            energy_value = value
        elif "carbohydrate" in name:
            carbs_value = value    

    if phe_value is None:
        phe_value = estimate_phe_from_protein(protein_value)

    return {
        "phe": phe_value,
        "protein": protein_value,
        "energy": energy_value,
        "carbs": carbs_value
    }


def classify_phe(phe_value):
    """
    Classify ingredient by PHE level.
    """
    if phe_value < 50:
        return "Safe"
    elif phe_value <= 100:
        return "Caution"
    else:
        return "Avoid"


def get_phe_for_ingredient(item, selected_types):
    """
    Given an ingredient name, search USDA, auto-select best match,
    retrieve nutrients, estimate PHE, and classify.
    """
    options = search_food_options(item, selected_types)
    if not options:
        print(f"⚠️ No USDA matches for '{item}'.")
        return None

    fdc_id = auto_select_best_option(options, item)
    if not fdc_id:
        print(f"⚠️ Could not auto-select option for '{item}'.")
        return None

    details = get_food_details(fdc_id)
    result = extract_phe_or_estimate(details)
    if result is None:
        return None
    
    phe = result["phe"]
    if phe is not None:
        result["flag"] = classify_phe(phe)
    else:
        result["flag"] = "No nutrition information found"

    return result


def analyze_ingredients(ingredient_list, selected_types):
    """
    Analyze a list of ingredients for PHE content.
    Return list of safe ingredients, total meal PHE, and nutrient summary.
    """
    total_phe = 0
    results = []
    safe_ingredients = []

    print("\n=== PKU Nutrition Analysis Results ===")
    
    for item in ingredient_list:
        result = get_phe_for_ingredient(item, selected_types)
        if result is None:
            print(f"⚠️ Skipped or no USDA info for '{item}'. Not adding to summary.")
            continue

        phe = result.get("phe")
        if phe is not None:
            total_phe += phe

        results.append({
            "ingredient": item,
            "phe": phe,
            "protein": result.get("protein"),
            "carbs": result.get("carbs"),
            "energy": result.get("energy"),
            "flag": result.get("flag", "No nutrition info found")
        })

        if result.get("flag") in ["Safe", "Caution"]:
            safe_ingredients.append(item)

    print("\n=== Nutrient Summary per 100g ===")
    for res in results:
        line = f"- {res['ingredient'].title()}: "
        if res["phe"] is not None:
            line += f"{res['phe']:.1f} mg PHE → {res['flag']}"
        else:
            line += f"⚠️ {res.get('flag', 'No nutrition info found')}"

        extras = []
        if res.get("protein") is not None:
            extras.append(f"Protein: {res['protein']}g")
        if res.get("carbs") is not None:
            extras.append(f"Carbs: {res['carbs']}g")
        if res.get("energy") is not None:
            extras.append(f"Energy: {res['energy']} kcal")
        
        if extras:
            line += " | " + " | ".join(extras)

        print(line)

    print("\n--- Meal Summary ---")
    print(f"Total estimated PHE in meal: {total_phe:.1f} mg")
    if total_phe < 250:
        print("⚠️ For adults: Below typical recommended range (250–500 mg/day).")
    elif total_phe > 500:
        print("⚠️ For adults: Above typical recommended range (250–500 mg/day).")
    else:
        print("✅ For adults: Within typical recommended range (250–500 mg/day).")

    if not safe_ingredients:
        print("\n⚠️ No Safe or Caution ingredients detected. Cannot generate recipe.")
    else:
        print("\n✅ Ingredients eligible for PKU-safe recipe:", ", ".join(safe_ingredients))

    return safe_ingredients, total_phe, results
