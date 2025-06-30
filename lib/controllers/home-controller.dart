import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pengaduan/models/news-api.dart';
import 'package:http/http.dart' as http;

class HomeController {
  static Future<List<NewsArticle>> getNews() async {
    final String apiKey = dotenv.env['KEY_NEWS'] ?? '';
    const String baseUrl = 'https://newsapi.org/v2';
    final response = await http.get(
      Uri.parse(
          '$baseUrl/everything?q=kekerasan+dalam+rumah+tangga&language=id&sortBy=publishedAt&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<NewsArticle> articles = [];

      for (var item in data['articles']) {
        articles.add(NewsArticle.fromJson(item));
      }

      return articles;
    } else {
      throw Exception('Failed to load news');
    }
  }
}