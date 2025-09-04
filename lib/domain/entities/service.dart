/// Domain entity representing a Service.
/// Kept free of framework and external dependencies.
class Service {
  final int id;
  final String title;
  final String body;

  const Service({required this.id, required this.title, required this.body});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service &&
        other.id == id &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ body.hashCode;

  @override
  String toString() => 'Service(id: $id, title: $title, body: $body)';
}
