import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'models/food_item.dart';
import 'models/workout.dart';
import 'meal_plan_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CalendarScreen(),
    const MealScreen(),
    const WorkoutScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Календарь',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant),
            label: 'Питание',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Тренировки',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            label: 'Аналитика',
          ),
        ],
      ),
    );
  }
}

// ========== КАЛЕНДАРЬ ==========
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Map<DateTime, List<Task>> _tasks = {};

  @override
  void initState() {
    super.initState();
    _loadSampleTasks();
  }

  void _loadSampleTasks() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final tomorrowDate = DateTime(today.year, today.month, today.day + 1);

    _tasks[todayDate] = [
      Task('Сделать зарядку', '07:00', Icons.fitness_center, Colors.green),
      Task('Позвонить клиенту', '10:30', Icons.phone, Colors.blue),
      Task('Купить продукты', '18:00', Icons.shopping_cart, Colors.orange),
    ];
    _tasks[tomorrowDate] = [
      Task('Встреча в 15:00', '15:00', Icons.meeting_room, Colors.purple),
      Task('Пробежка 5 км', '08:00', Icons.directions_run, Colors.green),
    ];
  }

  List<Task> _getTasksForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _tasks[date] ?? [];
  }

  void _addNewTask() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Новая задача'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Время (например, 14:30)'),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final date = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                  final newTask = Task(
                    titleController.text,
                    timeController.text.isEmpty ? '—' : timeController.text,
                    Icons.task,
                    Colors.blue,
                  );
                  setState(() {
                    if (_tasks.containsKey(date)) {
                      _tasks[date]!.add(newTask);
                    } else {
                      _tasks[date] = [newTask];
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksForDay = _getTasksForDay(_selectedDay);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.purple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Задачи на ${DateFormat('d MMMM').format(_selectedDay)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _addNewTask,
                        icon: const Icon(Icons.add_circle, color: Colors.purple, size: 32),
                      ),
                    ],
                  ),
                ),
                if (tasksForDay.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Нет задач на этот день',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _addNewTask,
                            child: const Text('Добавить задачу'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasksForDay.length,
                      itemBuilder: (context, index) {
                        final task = tasksForDay[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(task.icon, color: task.color),
                            title: Text(task.title),
                            subtitle: Text(task.time),
                            trailing: Checkbox(
                              value: false,
                              onChanged: (value) {},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Task {
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  Task(this.title, this.time, this.icon, this.color);
}

// ========== ПИТАНИЕ ==========
class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  DateTime _selectedDate = DateTime.now();
  
  final Map<DateTime, Map<String, List<FoodItem>>> _meals = {};
  
  final List<String> _mealTypes = ['Завтрак', 'Обед', 'Ужин', 'Перекус'];
  String _selectedMealType = 'Завтрак';

  final List<FoodItem> _foodDatabase = [
    FoodItem(id: '1', name: 'Куриная грудка', calories: 165, proteins: 31, fats: 3.6, carbs: 0),
    FoodItem(id: '2', name: 'Рис отварной', calories: 130, proteins: 2.7, fats: 0.3, carbs: 28),
    FoodItem(id: '3', name: 'Гречка', calories: 132, proteins: 4.5, fats: 2.3, carbs: 25),
    FoodItem(id: '4', name: 'Яблоко', calories: 52, proteins: 0.3, fats: 0.2, carbs: 14),
    FoodItem(id: '5', name: 'Творог 5%', calories: 121, proteins: 15, fats: 5, carbs: 4),
    FoodItem(id: '6', name: 'Яйцо куриное', calories: 155, proteins: 13, fats: 11, carbs: 1.1),
  ];

  @override
  void initState() {
    super.initState();
    _loadSampleMeals();
  }

  void _loadSampleMeals() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    _meals[todayDate] = {
      'Завтрак': [
        FoodItem(id: '2', name: 'Рис отварной', calories: 130, proteins: 2.7, fats: 0.3, carbs: 28),
        FoodItem(id: '6', name: 'Яйцо куриное', calories: 155, proteins: 13, fats: 11, carbs: 1.1),
      ],
      'Обед': [
        FoodItem(id: '1', name: 'Куриная грудка', calories: 165, proteins: 31, fats: 3.6, carbs: 0),
        FoodItem(id: '3', name: 'Гречка', calories: 132, proteins: 4.5, fats: 2.3, carbs: 25),
      ],
    };
  }

  Map<String, List<FoodItem>> _getMealsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _meals[date] ?? {};
  }

  void _addMealToDay(FoodItem food, String mealType) {
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    setState(() {
      if (!_meals.containsKey(date)) {
        _meals[date] = {};
      }
      if (!_meals[date]!.containsKey(mealType)) {
        _meals[date]![mealType] = [];
      }
      _meals[date]![mealType]!.add(food);
    });
  }

  void _removeMeal(FoodItem food, String mealType) {
    final date = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    
    setState(() {
      if (_meals.containsKey(date) && _meals[date]!.containsKey(mealType)) {
        _meals[date]![mealType]!.removeWhere((item) => item.id == food.id);
      }
    });
  }

  int _getTotalCaloriesForDay(DateTime day) {
    final meals = _getMealsForDay(day);
    int total = 0;
    for (var mealList in meals.values) {
      for (var food in mealList) {
        total += food.calories;
      }
    }
    return total;
  }

  Map<String, double> _getTotalMacrosForDay(DateTime day) {
    final meals = _getMealsForDay(day);
    double proteins = 0, fats = 0, carbs = 0;
    for (var mealList in meals.values) {
      for (var food in mealList) {
        proteins += food.proteins;
        fats += food.fats;
        carbs += food.carbs;
      }
    }
    return {'proteins': proteins, 'fats': fats, 'carbs': carbs};
  }

  void _showAddFoodDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: 450,
              child: Column(
                children: [
                  const Text('Добавить продукт', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMealType,
                    items: _mealTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setStateBottomSheet(() {
                        _selectedMealType = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Приём пищи'),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _foodDatabase.length,
                      itemBuilder: (context, index) {
                        final food = _foodDatabase[index];
                        return ListTile(
                          leading: const Icon(Icons.fastfood, color: Colors.purple),
                          title: Text(food.name),
                          subtitle: Text('${food.calories} ккал | Б:${food.proteins} Ж:${food.fats} У:${food.carbs}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            onPressed: () {
                              _addMealToDay(food, _selectedMealType);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${food.name} добавлен на $_selectedMealType')),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealsForDay = _getMealsForDay(_selectedDate);
    final totalCalories = _getTotalCaloriesForDay(_selectedDate);
    final macros = _getTotalMacrosForDay(_selectedDate);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Дневник питания'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.purple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealPlanScreen()),
              );
            },
            tooltip: 'Создать план питания с AI',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1);
              });
            },
          ),
          Text(
            DateFormat('d MMM yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$totalCalories', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                    const Text('ккал', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Text('${macros['proteins']!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const Text('белки', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Text('${macros['fats']!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Text('жиры', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                Column(
                  children: [
                    Text('${macros['carbs']!.toStringAsFixed(1)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    const Text('углеводы', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _mealTypes.length,
              itemBuilder: (context, index) {
                final mealType = _mealTypes[index];
                final foods = mealsForDay[mealType] ?? [];
                final mealCalories = foods.fold(0, (sum, f) => sum + f.calories);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Icon(
                      mealType == 'Завтрак' ? Icons.bedtime : 
                      mealType == 'Обед' ? Icons.lunch_dining :
                      mealType == 'Ужин' ? Icons.dinner_dining : Icons.cookie,
                      color: Colors.purple,
                    ),
                    title: Text(mealType, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$mealCalories ккал • ${foods.length} продуктов'),
                    children: foods.map((food) {
                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text('${food.calories} ккал | Б:${food.proteins} Ж:${food.fats} У:${food.carbs}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeMeal(food, mealType),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFoodDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ========== ДНЕВНИК ТРЕНИРОВОК (с добавлением) ==========
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Workout> _workouts = [];

  final Map<String, List<Map<String, dynamic>>> _exerciseTemplates = {
    'Грудные': [
      {'name': 'Жим лёжа', 'sets': 4, 'reps': 10},
      {'name': 'Жим гантелей', 'sets': 3, 'reps': 12},
      {'name': 'Сведение рук', 'sets': 3, 'reps': 15},
    ],
    'Спина': [
      {'name': 'Подтягивания', 'sets': 4, 'reps': 8},
      {'name': 'Тяга штанги', 'sets': 4, 'reps': 10},
      {'name': 'Тяга блока', 'sets': 3, 'reps': 12},
    ],
    'Ноги': [
      {'name': 'Приседания', 'sets': 4, 'reps': 10},
      {'name': 'Становая тяга', 'sets': 3, 'reps': 8},
      {'name': 'Выпады', 'sets': 3, 'reps': 12},
    ],
    'Плечи': [
      {'name': 'Жим штанги стоя', 'sets': 4, 'reps': 10},
      {'name': 'Махи гантелями', 'sets': 3, 'reps': 15},
      {'name': 'Тяга к подбородку', 'sets': 3, 'reps': 12},
    ],
    'Кардио': [
      {'name': 'Бег', 'sets': 1, 'reps': 1},
      {'name': 'Велотренажёр', 'sets': 1, 'reps': 1},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadSampleWorkouts();
  }

  void _loadSampleWorkouts() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    
    _workouts.addAll([
      Workout(
        id: '1',
        date: todayDate,
        title: '💪 Тренировка грудь + трицепс',
        exercises: [
          WorkoutExercise(id: '1', name: 'Жим лёжа', sets: 4, reps: 10, weight: 60),
          WorkoutExercise(id: '2', name: 'Жим гантелей', sets: 3, reps: 12, weight: 20),
        ],
        duration: 45,
      ),
    ]);
  }

  List<Workout> _getWorkoutsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _workouts.where((w) => 
      w.date.year == date.year && 
      w.date.month == date.month && 
      w.date.day == date.day
    ).toList();
  }

  void _showAddWorkoutDialog() {
    String selectedMuscleGroup = 'Грудные';
    List<WorkoutExercise> selectedExercises = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Новая тренировка', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Группа мышц', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _exerciseTemplates.keys.map((group) {
                      return FilterChip(
                        label: Text(group),
                        selected: selectedMuscleGroup == group,
                        onSelected: (selected) {
                          setStateBottomSheet(() {
                            selectedMuscleGroup = group;
                          });
                        },
                        selectedColor: Colors.purple.withOpacity(0.2),
                        checkmarkColor: Colors.purple,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Упражнения', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: _exerciseTemplates[selectedMuscleGroup]!.map((template) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(template['name']),
                            subtitle: Text('${template['sets']} x ${template['reps']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                final exercise = WorkoutExercise(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: template['name'],
                                  sets: template['sets'],
                                  reps: template['reps'],
                                  weight: 0,
                                );
                                setStateBottomSheet(() {
                                  selectedExercises.add(exercise);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${exercise.name} добавлен')),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(),
                  Text('Выбрано упражнений: ${selectedExercises.length}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: selectedExercises.isEmpty ? null : () {
                      final newWorkout = Workout(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: _selectedDate,
                        title: 'Тренировка ${_workouts.length + 1}',
                        exercises: selectedExercises,
                        duration: selectedExercises.length * 10,
                      );
                      setState(() {
                        _workouts.add(newWorkout);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Тренировка добавлена')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Сохранить тренировку'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutsForDay = _getWorkoutsForDay(_selectedDate);
    final totalWorkouts = _workouts.length;
    final totalExercises = _workouts.fold(0, (sum, w) => sum + w.exercises.length);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Дневник тренировок'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1);
              });
            },
          ),
          Text(
            DateFormat('d MMM yyyy').format(_selectedDate),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + 1);
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('$totalWorkouts', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                    const Text('всего тренировок', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('$totalExercises', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                    const Text('всего упражнений', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Тренировки на ${DateFormat('d MMMM').format(_selectedDate)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: workoutsForDay.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Нет тренировок на этот день', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showAddWorkoutDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить тренировку'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: workoutsForDay.length,
                    itemBuilder: (context, index) {
                      final workout = workoutsForDay[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: const Icon(Icons.fitness_center, color: Colors.purple),
                          ),
                          title: Text(workout.title),
                          subtitle: Text('${workout.exercises.length} упражнений • ${workout.duration} мин'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(workout.title),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: workout.exercises.map((e) => 
                                    ListTile(title: Text(e.name), subtitle: Text('${e.sets} x ${e.reps} • ${e.weight} кг'))
                                  ).toList(),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorkoutDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ========== АНАЛИТИКА И ИНСАЙТЫ ==========
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0; // 0 = неделя, 1 = месяц
  
  // Данные для графиков (позже можно заменить на реальные из БД)
  final List<double> _caloriesData = [2100, 2350, 1900, 2450, 2200, 2550, 2300];
  final List<double> _proteinData = [110, 125, 98, 132, 118, 140, 128];
  final List<double> _workoutData = [45, 60, 30, 75, 50, 90, 65];
  final List<String> _weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  
  final List<Map<String, dynamic>> _insights = [
    {'icon': Icons.trending_up, 'color': Colors.green, 'title': 'Прогресс +15%', 'subtitle': 'За последнюю неделю вы стали активнее'},
    {'icon': Icons.restaurant, 'color': Colors.orange, 'title': 'Средняя калорийность', 'subtitle': '2250 ккал/день • Цель: 2400 ккал'},
    {'icon': Icons.fitness_center, 'color': Colors.purple, 'title': 'Лучшая тренировка', 'subtitle': 'Пятница • 75 мин • 450 ккал'},
    {'icon': Icons.auto_awesome, 'color': Colors.blue, 'title': 'Совет AI', 'subtitle': 'Увеличьте потребление белка после тренировок'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Аналитика и инсайты'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            floating: true,
            actions: [
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Неделя')),
                  ButtonSegment(value: 1, label: Text('Месяц')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<int> selection) {
                  setState(() {
                    _selectedPeriod = selection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.purple;
                    }
                    return Colors.grey[200];
                  }),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          
          // График калорий
          SliverToBoxAdapter(
            child: _buildCaloriesChart(),
          ),
          
          // Графики белков и тренировок
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _buildProteinChart(),
                _buildWorkoutChart(),
              ]),
            ),
          ),
          
          // Инсайты
          SliverToBoxAdapter(
            child: _buildInsightsSection(),
          ),
          
          // Совет AI
          SliverToBoxAdapter(
            child: _buildAITip(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCaloriesChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.local_fire_department, color: Colors.orange), const SizedBox(width: 8), const Text('Калорийность', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < _weekDays.length) return Text(_weekDays[value.toInt()]);
                    return const Text('');
                  }, reservedSize: 30)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _caloriesData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: true, color: Colors.orange.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProteinChart() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.fastfood, color: Colors.blue), const SizedBox(width: 4), const Text('Белки (г)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 160,
              titlesData: FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: _proteinData.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value, color: Colors.blue, width: 20, borderRadius: BorderRadius.circular(4))])).toList(),
            )),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWorkoutChart() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.fitness_center, color: Colors.purple), const SizedBox(width: 4), const Text('Тренировки (мин)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              titlesData: FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: _workoutData.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value, color: Colors.purple, width: 20, borderRadius: BorderRadius.circular(4))])).toList(),
            )),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.lightbulb, color: Colors.amber), const SizedBox(width: 8), const Text('Инсайты и рекомендации', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          ..._insights.map((insight) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5)]),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (insight['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(insight['icon'], color: insight['color'], size: 24)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(insight['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(insight['subtitle'], style: TextStyle(color: Colors.grey[600], fontSize: 13))])),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  Widget _buildAITip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.purple[600]!, Colors.purple[800]!]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20)), const SizedBox(width: 12), const Text('Совет AI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 16),
          const Text('На основе ваших данных: увеличьте потребление белка после тренировок. Попробуйте добавить протеиновый коктейль в дни занятий.', style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}