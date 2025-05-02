import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NewsService {

  static Future<List<NewsArticle>> getNews() async {
    final String apiKey = dotenv.env['KEY_NEWS'] ?? '';
    const String baseUrl = 'https://newsapi.org/v2';
    final response = await http.get(
      Uri.parse(
          '$baseUrl/everything?q=kekerasan+seksual&language=id&sortBy=publishedAt&apiKey=$apiKey'),
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

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String urlToImage;
  final String publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      urlToImage: json['urlToImage'] ?? '',
      publishedAt: json['publishedAt'] ?? '',
    );
  }
}
