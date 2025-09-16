import '../../domain/entities/service.dart';

/// Data model representing a Service fetched from the API.
/// Extends [Service] entity to keep domain layer pure.
class ServiceModel extends Service {
  const ServiceModel({
    required super.id,
    required super.title,
    required super.body,
  });

  /// Creates a [ServiceModel] from JSON response.
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['category'] as String? ?? '',
    );
  }

  /// Converts [ServiceModel] to JSON (not strictly needed here,
  /// but useful if posting back or persisting full objects).
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'body': body};
  }

  /// Converts this data model into the domain entity [Service]
  Service toEntity() {
    return Service(id: id, title: title, body: body);
  }
}
