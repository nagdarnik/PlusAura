class FoodItem {
  final String id;
  final String name;
  final int calories;    // ккал
  final double proteins; // белки (г)
  final double fats;     // жиры (г)
  final double carbs;    // углеводы (г)

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.carbs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'proteins': proteins,
      'fats': fats,
      'carbs': carbs,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      proteins: json['proteins'],
      fats: json['fats'],
      carbs: json['carbs'],
    );
  }
}