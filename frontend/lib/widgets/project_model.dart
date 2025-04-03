class Project {
  final int id;
  final String name;
  bool isOwner;

  Project({
    required this.id,
    required this.name,
    this.isOwner = false,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
    );
  }
}
