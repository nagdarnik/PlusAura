import 'package:flutter/material.dart';
import 'services/gpt_service.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  // Контроллеры для формы
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  String _gender = 'female';
  String _goal = 'weight_loss';
  String _activityLevel = 'moderate';
  final List<String> _allergies = [];
  String _dietType = 'none';
  
  bool _isLoading = false;
  Map<String, dynamic>? _mealPlan;
  
  final List<String> _allergiesList = [
    'Орехи', 'Молочные продукты', 'Глютен', 'Яйца', 'Морепродукты', 'Соя'
  ];
  
  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
  
  Future<void> _generateMealPlan() async {
    // Валидация
    if (_ageController.text.isEmpty || 
        _heightController.text.isEmpty || 
        _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Вызов GPTService с правильными параметрами
      final mealPlan = await GPTService.generateMealPlan(
        age: int.parse(_ageController.text),
        gender: _gender,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        goal: _goal,
        activityLevel: _activityLevel,
        allergies: _allergies,
        dietType: _dietType,
      );
      
      setState(() {
        _mealPlan = mealPlan;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('План питания успешно создан!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('План питания с AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.purple),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_mealPlan != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.purple),
              onPressed: () => setState(() => _mealPlan = null),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 20),
                  Text('Генерируем персонализированный план...'),
                  SizedBox(height: 8),
                  Text('Это может занять несколько секунд', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : _mealPlan == null
              ? _buildForm()
              : _buildMealPlan(),
    );
  }
  
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIBanner(),
          const SizedBox(height: 24),
          _buildGenderSelector(),
          const SizedBox(height: 16),
          _buildBodyInputs(),
          const SizedBox(height: 16),
          _buildGoalDropdown(),
          const SizedBox(height: 16),
          _buildActivityDropdown(),
          const SizedBox(height: 16),
          _buildDietDropdown(),
          const SizedBox(height: 16),
          _buildAllergiesSection(),
          const SizedBox(height: 32),
          _buildGenerateButton(),
          const SizedBox(height: 24),
          _buildInfoNote(),
        ],
      ),
    );
  }
  
  Widget _buildAIBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[600]!, Colors.purple[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Персональный AI-план питания', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('На основе ваших данных GPT составит идеальное меню', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Пол', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Женский'),
                selected: _gender == 'female',
                onSelected: (selected) => setState(() => _gender = 'female'),
                selectedColor: Colors.purple,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(color: _gender == 'female' ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Text('Мужской'),
                selected: _gender == 'male',
                onSelected: (selected) => setState(() => _gender = 'male'),
                selectedColor: Colors.purple,
                backgroundColor: Colors.grey[200],
                labelStyle: TextStyle(color: _gender == 'male' ? Colors.white : Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildBodyInputs() {
    return Row(
      children: [
        Expanded(child: _buildTextField(_ageController, 'Возраст', Icons.cake)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField(_heightController, 'Рост (см)', Icons.height)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField(_weightController, 'Вес (кг)', Icons.monitor_weight)),
      ],
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
  
  Widget _buildGoalDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Цель', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _goal,
          items: const [
            DropdownMenuItem(value: 'weight_loss', child: Text('🏃‍♀️ Похудение')),
            DropdownMenuItem(value: 'maintenance', child: Text('⚖️ Поддержание веса')),
            DropdownMenuItem(value: 'muscle_gain', child: Text('💪 Набор мышечной массы')),
          ],
          onChanged: (value) => setState(() => _goal = value!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
  
  Widget _buildActivityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Уровень активности', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _activityLevel,
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('🛋️ Сидячий')),
            DropdownMenuItem(value: 'light', child: Text('🚶 Легкая активность')),
            DropdownMenuItem(value: 'moderate', child: Text('🏃 Умеренная активность')),
            DropdownMenuItem(value: 'active', child: Text('🔥 Высокая активность')),
          ],
          onChanged: (value) => setState(() => _activityLevel = value!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
  
  Widget _buildDietDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тип питания', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _dietType,
          items: const [
            DropdownMenuItem(value: 'none', child: Text('🍽️ Без ограничений')),
            DropdownMenuItem(value: 'vegetarian', child: Text('🥬 Вегетарианство')),
            DropdownMenuItem(value: 'vegan', child: Text('🌱 Веганство')),
            DropdownMenuItem(value: 'gluten_free', child: Text('🌾 Без глютена')),
          ],
          onChanged: (value) => setState(() => _dietType = value!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }
  
  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Аллергии (можно выбрать несколько)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allergiesList.map((allergy) {
            return FilterChip(
              label: Text(allergy),
              selected: _allergies.contains(allergy),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _allergies.add(allergy);
                  } else {
                    _allergies.remove(allergy);
                  }
                });
              },
              selectedColor: Colors.purple.withOpacity(0.2),
              checkmarkColor: Colors.purple,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _generateMealPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 12),
            Text('Сгенерировать план питания', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'План питания создаётся искусственным интеллектом на основе ваших данных',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMealPlan() {
    final weeklyPlan = _mealPlan!['weekly_plan'];
    final days = weeklyPlan.keys.toList();
    
    final List<Widget> tabViews = [];
    for (var day in days) {
      final meals = weeklyPlan[day];
      tabViews.add(
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildMealCard('🍳 Завтрак', meals['Завтрак'] ?? 'Не указан', Icons.bedtime, Colors.orange),
              const SizedBox(height: 12),
              _buildMealCard('🥗 Обед', meals['Обед'] ?? 'Не указан', Icons.lunch_dining, Colors.green),
              const SizedBox(height: 12),
              _buildMealCard('🍲 Ужин', meals['Ужин'] ?? 'Не указан', Icons.dinner_dining, Colors.purple),
              const SizedBox(height: 12),
              _buildMealCard('🍎 Перекус', meals['Перекус'] ?? 'Не указан', Icons.cookie, Colors.blue),
            ],
          ),
        ),
      );
    }
    
    final List<Tab> tabs = [];
    for (var day in days) {
      tabs.add(Tab(text: day));
    }
    
    return DefaultTabController(
      length: days.length,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('${_mealPlan!['calories']}', 'ккал/день', Colors.purple),
                  _buildStatColumn('${_mealPlan!['protein']}г', 'белки', Colors.blue),
                  _buildStatColumn('${_mealPlan!['fats']}г', 'жиры', Colors.orange),
                  _buildStatColumn('${_mealPlan!['carbs']}г', 'углеводы', Colors.green),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                tabs: tabs,
                labelColor: Colors.purple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.purple,
                indicatorWeight: 3,
              ),
            ),
            Expanded(
              child: TabBarView(
                children: tabViews,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
  
  Widget _buildMealCard(String title, String description, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: const TextStyle(fontSize: 14)),
        trailing: Icon(Icons.add_circle_outline, color: Colors.purple[400]),
      ),
    );
  }
}