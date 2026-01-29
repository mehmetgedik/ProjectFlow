class Project {
  final String id;
  final String name;
  final String identifier;

  const Project({
    required this.id,
    required this.name,
    required this.identifier,
  });

  factory Project.fromJson(Map json) {
    return Project(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      identifier: (json['identifier'] ?? '').toString(),
    );
  }
}

