class Medication {
  final String name;
  final int dosageMg;

  Medication({required this.name, required this.dosageMg});

  Map<String, dynamic> toMap() => {
        'name': name,
        'dosageMg': dosageMg,
      };

  factory Medication.fromMap(Map<String, dynamic> map) =>
      Medication(name: map['name'], dosageMg: map['dosageMg']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Medication &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          dosageMg == other.dosageMg;

  @override
  int get hashCode => name.hashCode ^ dosageMg.hashCode;
}