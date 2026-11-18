import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

import '../models/post_model.dart';

class PostService {
  static const String _apiUrl = 'https://jsonplaceholder.typicode.com/posts';
  static const String _boxName = 'postsBox';

  Box<Post> get _box => Hive.box<Post>(_boxName);

  Future<List<Post>> getPosts() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
      );

      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body) as List<dynamic>;
        final List<Post> onlinePosts =
            decoded.map((dynamic e) => Post.fromJson(e as Map<String, dynamic>)).toList();

        final Box<Post> box = _box;
        await box.clear();
        await box.addAll(onlinePosts);

        debugPrint('Loaded from API and cached to Hive: ${onlinePosts.length}');
        return onlinePosts;
      }

      // Non-200 response: fall through to offline cache.
      throw Exception('API responded with status ${response.statusCode}');
    } catch (_) {
      final Box<Post> box = _box;
      if (box.isNotEmpty) {
        debugPrint('Loaded from Hive offline: ${box.length}');
        return box.values.toList();
      }
      throw Exception('No Internet and No Cached Data');
    }
  }
}