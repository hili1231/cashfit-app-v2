class Exercise {
  final String name;
  final String image;
  final int sets;
  final int reps;
  final String instructions;
  final int day; // <--- new field for day-based grouping

  Exercise({
    required this.name,
    required this.image,
    required this.sets,
    required this.reps,
    required this.instructions,
    required this.day, // <--- new field
  });
}
