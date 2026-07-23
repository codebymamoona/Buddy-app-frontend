class FoodPreferences {
  final String? favoriteCuisine;
  final String? favoriteDish;
  final String? favoriteBrand;
  final String? spiceLevel;
  final String? dietaryRestriction;
  final double? typicalBudget;

  FoodPreferences({
    this.favoriteCuisine,
    this.favoriteDish,
    this.favoriteBrand,
    this.spiceLevel,
    this.dietaryRestriction,
    this.typicalBudget,
  });
}

class TravelPlace {
  final String name;
  final String? reason;
  final String? style;

  TravelPlace({required this.name, this.reason, this.style});
}

class UserPreferences {
  final FoodPreferences food;
  final List<TravelPlace> travelPlaces;

  UserPreferences({
    FoodPreferences? food,
    this.travelPlaces = const [],
  })  : food = food ?? FoodPreferences();
}