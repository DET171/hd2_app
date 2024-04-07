import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> loadJson(String jsonPath) async {
  final jsonString = await rootBundle.loadString(jsonPath);
  return jsonDecode(jsonString);
}

Future<dynamic> fetchData(url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to load data');
  }
}