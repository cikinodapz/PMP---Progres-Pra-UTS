import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String _baseUrlMobile = 'http://192.168.18.66:3000'; //wifi daffa
  // static const String _baseUrlMobile = 'http://192.168.100.117:3000'; //wifi baarasobadan

  static const String _baseUrlWeb = 'http://192.168.18.66:3000';
  static String get baseUrl => kIsWeb ? _baseUrlWeb : _baseUrlMobile;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', token);
          print('Token saved to SharedPreferences: $token');
        } else {
          throw Exception('No token received from server');
        }
        return data;
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      print('Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      print('Register response status: ${response.statusCode}');
      print('Register response body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      print('Register error: $e');
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> saveFCMToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved auth token for saveFCMToken: $token');

    if (token == null) {
      throw Exception('No auth token found. Please login first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/user/save-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcmToken': fcmToken, 'authToken': token}),
    );

    print('SaveFCMToken status: ${response.statusCode}');
    print('SaveFCMToken body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to save FCM token: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for profile: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('GetProfile status: ${response.statusCode}');
    print('GetProfile body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['user'];
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/getAllDeck'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('GetAllDeck status: ${response.statusCode}');
    print('GetAllDeck body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['decks'];
    } else {
      throw Exception('Failed to fetch decks: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createDeck(String name, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for createDeck: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/user/createDeck'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'category': category}),
    );

    print('CreateDeck status: ${response.statusCode}');
    print('CreateDeck body: ${response.body}');

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create deck: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> deleteDeck(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for deleteDeck: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/user/hapusDeck/$deckId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('DeleteDeck status: ${response.statusCode}');
    print('DeleteDeck body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete deck: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> editDeck(
    String deckId,
    String name,
    String category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for editDeck: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/user/editDeck/$deckId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'category': category}),
    );

    print('EditDeck status: ${response.statusCode}');
    print('EditDeck body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to edit deck: ${response.body}');
    }
  }

  Future<List<dynamic>> getFlashcards(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for getFlashcards: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/listCard/$deckId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('GetFlashcards status: ${response.statusCode}');
    print('GetFlashcards body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['flashcards'];
    } else {
      throw Exception('Failed to fetch flashcards: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> addFlashcard(
    String deckId,
    String question,
    String answer,
    File? image,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for addFlashcard: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/user/addCard/$deckId'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['question'] = question;
    request.fields['answer'] = answer;

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('AddFlashcard status: ${response.statusCode}');
    print('AddFlashcard body: $responseBody');

    if (response.statusCode == 201) {
      return jsonDecode(responseBody);
    } else {
      throw Exception('Failed to add flashcard: $responseBody');
    }
  }

  Future<Map<String, dynamic>> deleteFlashcard(String flashcardId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for deleteFlashcard: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/user/deleteCard/$flashcardId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('DeleteFlashcard status: ${response.statusCode}');
    print('DeleteFlashcard body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete flashcard: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> editFlashcard(
    String flashcardId,
    String question,
    String answer,
    File? imageFile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for editFlashcard: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/user/editCard/$flashcardId'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['question'] = question;
    request.fields['answer'] = answer;

    if (imageFile != null) {
      print('Uploading image: ${imageFile.path}');
      try {
        if (await imageFile.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath('image', imageFile.path),
          );
        } else {
          print('Image file does not exist: ${imageFile.path}');
          throw Exception('Selected image is invalid or inaccessible');
        }
      } catch (e) {
        print('Error preparing image: $e');
        throw Exception('Failed to prepare image: $e');
      }
    } else {
      print('No new image selected for edit');
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('EditFlashcard status: ${response.statusCode}');
      print('EditFlashcard body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        throw Exception('Flashcard not found: ${response.body}');
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('EditFlashcard error: $e');
      rethrow;
    }
  }

  Future<void> copyFlashcards(String deckId, List<String> flashcardIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for copyFlashcards: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/user/decks/$deckId/copy-flashcards'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'flashcardIds': flashcardIds}),
    );

    print('CopyFlashcards status: ${response.statusCode}');
    print('CopyFlashcards body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to copy flashcards: ${response.body}');
    }
  }

  Future<void> moveFlashcards(
    String targetDeckId,
    List<String> flashcardIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/flashcards/move'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'flashcardIds': flashcardIds,
          'targetDeckId': targetDeckId,
        }),
      );

      print('MoveFlashcards status: ${response.statusCode}');
      print('MoveFlashcards body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to move flashcards: ${response.body}');
      }
    } catch (e) {
      print('MoveFlashcards error: $e');
      throw Exception('Failed to move flashcards: $e');
    }
  }

  Future<Map<String, dynamic>> startQuiz(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for startQuiz: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/quiz/$deckId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('StartQuiz status: ${response.statusCode}');
    print('StartQuiz body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start quiz: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> submitAnswer(
    String flashcardId,
    String userAnswer,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for submitAnswer: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/user/quiz/$flashcardId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'userAnswer': userAnswer}),
    );

    print('SubmitAnswer status: ${response.statusCode}');
    print('SubmitAnswer body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit answer: ${response.body}');
    }
  }

  Future<List<dynamic>> getHistory({DateTime? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for history: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final uri = Uri.parse('$baseUrl/user/history').replace(
      queryParameters:
          date != null
              ? {
                'date':
                    DateTime(date.year, date.month, date.day).toIso8601String(),
              }
              : null,
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('GetHistory status: ${response.statusCode}');
    print('GetHistory body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['history'];
    } else {
      throw Exception('Failed to fetch history: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved token for stats: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('GetStats status: ${response.statusCode}');
    print('GetStats body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stats'];
    } else {
      throw Exception('Failed to fetch stats: ${response.body}');
    }
  }
}
