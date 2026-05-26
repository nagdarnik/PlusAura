import 'dart:convert';
import 'package:http/http.dart' as http;

class GPTService {
  static const String _baseUrl = 'http://localhost:8000';
  
  // ========== АВТОРИЗАЦИЯ ==========
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    print('📤 РЕГИСТРАЦИЯ: $name, $email');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      print('📥 Статус: ${response.statusCode}');
      print('📥 Ответ: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Ошибка: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    print('📤 ЛОГИН: $email');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('📥 Статус: ${response.statusCode}');
      print('📥 Ответ: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Ошибка: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
  
  // ========== AI ПЛАН ПИТАНИЯ (исправленная версия) ==========
  static Future<Map<String, dynamic>> generateMealPlan({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String goal,
    required String activityLevel,
    required List<String> allergies,
    required String dietType,
  }) async {
    print('📤 ГЕНЕРАЦИЯ ПЛАНА ПИТАНИЯ');
    
    final userData = {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'goal': goal,
      'activity_level': activityLevel,
      'allergies': allergies,
      'diet_type': dietType,
    };
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate_meal_plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      print('📥 Статус: ${response.statusCode}');
      print('📥 Ответ: ${response.body}');
      return jsonDecode(response.body);
    } catch (e) {
      print('❌ Ошибка: $e');
      return _getDemoPlan();
    }
  }
  
  // ========== ДЕМО-ПЛАН (на случай ошибки) ==========
  static Map<String, dynamic> _getDemoPlan() {
    return {
      'calories': 2200,
      'protein': 120,
      'fats': 70,
      'carbs': 250,
      'weekly_plan': {
        'Понедельник': {'Завтрак': 'Овсянка с ягодами (450 ккал)', 'Обед': 'Куриная грудка с гречкой (580 ккал)', 'Ужин': 'Рыба на пару (420 ккал)', 'Перекус': 'Яблоко (80 ккал)'},
        'Вторник': {'Завтрак': 'Яичница с авокадо (420 ккал)', 'Обед': 'Салат с тунцом (500 ккал)', 'Ужин': 'Говядина с овощами (550 ккал)', 'Перекус': 'Йогурт (120 ккал)'},
        'Среда': {'Завтрак': 'Творожная запеканка (380 ккал)', 'Обед': 'Суп-пюре из тыквы (450 ккал)', 'Ужин': 'Куриные котлеты (500 ккал)', 'Перекус': 'Банан (100 ккал)'},
        'Четверг': {'Завтрак': 'Смузи из шпината (350 ккал)', 'Обед': 'Рис с овощами (480 ккал)', 'Ужин': 'Индейка с киноа (520 ккал)', 'Перекус': 'Морковь (40 ккал)'},
        'Пятница': {'Завтрак': 'Панкейки (400 ккал)', 'Обед': 'Лосось с овощами (600 ккал)', 'Ужин': 'Салат Цезарь (480 ккал)', 'Перекус': 'Груша (90 ккал)'},
        'Суббота': {'Завтрак': 'Омлет с грибами (440 ккал)', 'Обед': 'Борщ с курицей (520 ккал)', 'Ужин': 'Стейк из лосося (550 ккал)', 'Перекус': 'Смузи (140 ккал)'},
        'Воскресенье': {'Завтрак': 'Рисовая каша (370 ккал)', 'Обед': 'Запечённая курица (560 ккал)', 'Ужин': 'Рагу овощное (440 ккал)', 'Перекус': 'Салат фруктовый (120 ккал)'},
      }
    };
  }
  
  // ========== ЗАДАЧИ ==========
  static Future<Map<String, dynamic>> createTask(String title, String time, DateTime date) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'task_time': time,
          'task_date': date.toIso8601String().split('T')[0]
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<List<dynamic>> getTasks(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$dateStr'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }
  
  // ========== ПИТАНИЕ ==========
  static Future<Map<String, dynamic>> addMeal({
    required DateTime date,
    required String mealType,
    required String foodName,
    required int calories,
    required double proteins,
    required double fats,
    required double carbs,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/meals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'meal_date': date.toIso8601String().split('T')[0],
          'meal_type': mealType,
          'food_name': foodName,
          'calories': calories,
          'proteins': proteins,
          'fats': fats,
          'carbs': carbs,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<List<dynamic>> getMeals(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$_baseUrl/meals/$dateStr'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }
  
  // ========== ТРЕНИРОВКИ ==========
  static Future<Map<String, dynamic>> createWorkout({
    required DateTime date,
    required String title,
    required int duration,
    required List<Map<String, dynamic>> exercises,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/workouts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workout_date': date.toIso8601String().split('T')[0],
          'title': title,
          'duration': duration,
          'exercises': exercises,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<List<dynamic>> getWorkouts(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final response = await http.get(
        Uri.parse('$_baseUrl/workouts/$dateStr'),
        headers: {'Content-Type': 'application/json'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return [];
    }
  }
}