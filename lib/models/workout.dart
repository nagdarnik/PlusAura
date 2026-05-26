class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double weight;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });
}

class Workout {
  final String id;
  final DateTime date;
  final String title;
  final List<WorkoutExercise> exercises;
  final int duration;

  Workout({
    required this.id,
    required this.date,
    required this.title,
    required this.exercises,
    required this.duration,
  });
}