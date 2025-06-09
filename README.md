# PKU Wise

PKU Wise is an AI-powered Flutter application designed to help individuals with Phenylketonuria (PKU) manage their dietary intake safely and conveniently. By leveraging OCR, NLP, and an integrated language model, PKU Wise enables users to scan or input food labels and ingredients, receive personalized nutritional breakdowns, and get risk-based safety alerts based on phenylalanine thresholds.

## Features

* **Food Label Scanner:** Use your camera to capture or upload food label images and extract key nutrients (PHE, protein, energy, carbohydrates) using OCR and NLP.
* **Ingredient-Based Recipes:** Enter custom ingredients to generate PKU-safe recipes via an integrated language model, complete with ingredient list and step-by-step instructions.
* **Nutritional Analysis:** View detailed nutritional breakdowns, including PHE content and macronutrient distribution for both labels and recipes.
* **Safety Alerts:** Receive risk-based alerts (Safe, Caution, Avoid) based on configurable PHE thresholds to help you make informed dietary choices.
* **User Profile:** Save your dietary preferences, PHE limits, and track consumption history to monitor daily intake.
* **Settings & Customization:** Adjust PHE thresholds, notification preferences, and manage account settings.

## Getting Started

This project is a starting point for the PKU Wise Flutter application.

### Prerequisites

* Flutter SDK (version 3.0 or later)
* Dart SDK (included with Flutter)
* Xcode (for iOS development) or Android Studio (for Android development)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/pku-wise.git
cd pku-wise

# Install dependencies
flutter pub get
```

### Running the App

```bash
# Launch on connected device or emulator
flutter run
```

## Project Structure

```
lib/
├── main.dart            # App entry point
├── screens/             # UI screens (Home, Scanner, Recipe, Settings)
├── widgets/             # Reusable UI components
├── services/            # OCR, NLP, and API integration logic
└── models/              # Data models (FoodItem, Recipe, UserProfile)
assets/
├── images/              # App images and icons
└── fonts/               # Custom fonts
test/                    # Unit and integration tests
```

## Contributing

We welcome contributions from the community! To contribute:

1. Fork the repository.
2. Create a new feature branch: `git checkout -b feature-name`.
3. Commit your changes: `git commit -m "Add awesome feature"`.
4. Push to the branch: `git push origin feature-name`.
5. Open a pull request.

Please ensure your code follows our coding standards and includes relevant tests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions, feedback, or support, please reach out to:

* **Pedro Modolo** (Mentor) — [pedro.modolo@kean.edu](mailto:pedro.modolo@kean.edu)
* **Dr. Malihe Aliasgari** (Lead Mentor)

Enjoy using PKU Wise and thank you for contributing to safer, personalized dietary management for individuals with PKU!
