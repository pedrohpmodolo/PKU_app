from backend.API_nutrition_analysis import choose_data_types, analyze_ingredients
from backend.llm import generate_pku_safe_recipe_langchain

def main():
    """
    Main loop for PKU Assistant CLI.
    Tracks daily PHE intake and offers recipe suggestions.
    """
    daily_phe_total = 0

    print("\n👩‍🍳 Welcome to the PKU Nutrition Assistant!")
    print("This app helps you track phenylalanine (PHE) intake and suggest PKU-safe recipes.\n")

    selected_types = choose_data_types()

    while True:
        user_input = input("\n📝 Enter ingredients separated by commas (or type 'q' to quit): ").strip()
        if user_input.lower() == 'q':
            print(f"\n👋 Goodbye! Total PHE consumed this session: {daily_phe_total:.1f} mg")
            break

        # Process input
        ingredients = [item.strip() for item in user_input.split(",") if item.strip()]
        if not ingredients:
            print("⚠️ Please enter at least one ingredient!")
            continue

        # Analyze ingredients for PHE content
        safe_ingredients, meal_phe, nutrition_summary = analyze_ingredients(ingredients, selected_types)
        daily_phe_total += meal_phe

        print(f"\n✅ Today's running total PHE intake: {daily_phe_total:.1f} mg")

        # Daily limit warning
        if daily_phe_total > 500:
            print("⚠️ WARNING: You have exceeded the typical daily recommended PHE limit!")

        # Offer recipe suggestion
        if safe_ingredients:
            choice = input("\n🤔 Would you like me to suggest a PKU-safe recipe using these ingredients? (Y/n): ").strip().lower()
            if choice in ["", "y", "yes"]:
                print("\n🍲 Generating your PKU-safe recipe. Please wait...")
                recipe = generate_pku_safe_recipe_langchain(safe_ingredients)
                print("\n=== PKU-Safe Recipe ===")
                print(recipe)
            else:
                print("\n✅ Okay! No recipe generated this time.")
        else:
            print("\n⚠️ No suitable ingredients for recipe generation.")

if __name__ == "__main__":
    main()
