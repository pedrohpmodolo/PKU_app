from langchain_ollama import OllamaLLM
import os

def load_prompt_template():
    current_dir = os.path.dirname(os.path.abspath(__file__))
    prompt_path = os.path.join(current_dir, "prompt.txt")
    with open(prompt_path, "r", encoding="utf-8") as file:
        return file.read()


def build_context_from_nutrition_data(nutrition_summary):
    """
    Converts nutrition summary into a context string for RAG prompts.
    """
    context_lines = []
    for item in nutrition_summary:
        line = f"{item['ingredient'].title()}:\n"
        if item.get("phe") is not None:
            line += f"- PHE: {item['phe']:.1f} mg/100g\n"
        if item.get("protein") is not None:
            line += f"- Protein: {item['protein']}g\n"
        if item.get("carbs") is not None:
            line += f"- Carbs: {item['carbs']}g\n"
        if item.get("energy") is not None:
            line += f"- Energy: {item['energy']} kcal\n"
        line += f"- Flag: {item['flag']}"
        context_lines.append(line)
    return "\n\n".join(context_lines)

from difflib import SequenceMatcher

def is_similar(a, b, threshold=0.8):
    return SequenceMatcher(None, a, b).ratio() > threshold

from nltk.corpus import words
import re

def find_llm_added_ingredients(llm_output, original_ingredients):
    original_lower = [i.lower() for i in original_ingredients]
    output_lines = llm_output.lower().splitlines()
    mentioned = set()

    english_words = set(words.words())
    food_keywords = {"beans", "banana", "milk", "cheese", "egg", "oil", "bread", "tofu", "sugar", "fruit", "rice", "spinach", "tomato", "potato", "butter", "pasta", "yogurt", "juice"}

    for line in output_lines:
        if "ingredient" in line or line.strip().startswith("-"):
            tokens = re.findall(r'\b[a-zA-Z]+\b', line)
            for token in tokens:
                if (
                    token not in original_lower
                    and token in food_keywords
                    and token in english_words
                ):
                    mentioned.add(token)

    return mentioned

def generate_pku_safe_recipe_with_rag(ingredients, nutrition_summary):
    """
    Generates a PKU-safe recipe using ingredients AND retrieved nutrition data.
    """
    llm = OllamaLLM(model="mistral")

    context = build_context_from_nutrition_data(nutrition_summary)
    template = load_prompt_template()

    prompt = template.format(
        ingredients=", ".join(ingredients),
        context=context,
        recipe="some recipe",
        instructions="...",
        estimated_phe="..."
    )


    recipe = llm.invoke(prompt)

    extra_ingredients = find_llm_added_ingredients(recipe, ingredients)
    if extra_ingredients:
        print("⚠️ LLM added ingredients not in list:", extra_ingredients)
    
    return {
        "recipe": recipe,
        "extra_ingredients": list(extra_ingredients)
    }

