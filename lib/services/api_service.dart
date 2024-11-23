import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class ApiService {
  static const String _baseUrl = 'https://opentdb.com';

  // get category from API
  static Future<List<Category>> fetchCategories() async {
    final url = Uri.parse('$_baseUrl/api_category.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List categoriesJson = data['trivia_categories'];
      return categoriesJson.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // get questions from API
  static Future<List<dynamic>> fetchQuestions({
    required int amount,
    required int category,
    required String difficulty,
    required String type,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/api.php?amount=$amount&category=$category&difficulty=$difficulty&type=$type',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['response_code'] == 0) {
        return data['results'];
      } else if (data['response_code'] == 1) {
        throw Exception('Not enough questions for the given settings.');
      } else if (data['response_code'] == 2) {
        throw Exception('Invalid parameter.');
      } else {
        throw Exception('Unknown error occurred.');
      }
    } else {
      throw Exception('Failed to load questions.');
    }
  }
}
