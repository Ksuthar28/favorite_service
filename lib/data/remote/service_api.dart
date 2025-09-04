import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/service_model.dart';

/// API client responsible for fetching services from the remote endpoint.
class ServiceApi {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';

  /// Fetches a paginated list of services from the API.
  /// [page] = current page number, [limit] = number of items per page.
  /// Returns a list of [ServiceModel].
  Future<List<ServiceModel>> fetchServices({
    int page = 1,
    int limit = 20,
  }) async {
    final url = Uri.parse('$_baseUrl/posts?_page=$page&_limit=$limit');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => ServiceModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch services: ${response.statusCode}');
    }
  }
}
