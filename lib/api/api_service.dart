import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:3000'; // Sesuaikan dengan IP Anda atau localhost

  Future<Map<String, dynamic>> login(String email, String password) async {
    print('Attempting to login with email: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<List<dynamic>> getAllDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
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
    final token = prefs.getString('token');
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
    final token = prefs.getString('token');
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
    final token = prefs.getString('token');
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

  // Fungsi baru untuk mengambil daftar flashcard
  Future<List<dynamic>> getFlashcards(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
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
    File? imageFile,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Retrieved token for addFlashcard: $token');

    if (token == null) {
      throw Exception('No token found. Please login first.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/user/addCard/$deckId'),
    );

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';
    // Don't set Content-Type header for multipart/form-data, it will be set automatically

    // Add fields
    request.fields['question'] = question;
    request.fields['answer'] = answer;

    // Add image if present
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    try {
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('AddFlashcard status: ${response.statusCode}');
      print('AddFlashcard body: ${response.body}');

      // Parse response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${responseData['message'] ?? response.body}',
        );
      }
    } catch (e) {
      print('AddFlashcard error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteFlashcard(String flashcardId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
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
    final token = prefs.getString('token');
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

  // Tambahkan di api_service.dart
Future<Map<String, dynamic>> startQuiz(String deckId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

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
  final token = prefs.getString('token');

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

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to submit answer: ${response.body}');
  }
}
}
