import 'package:efeflascard/screen/create_flashcard_page.dart';
import 'package:efeflascard/screen/flashcard_set_detail_page.dart';
import 'package:efeflascard/screen/study_mode_page.dart';
import 'package:flutter/material.dart';
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashCard App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade900,
        colorScheme: ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/flashcard-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return FlashcardSetDetailPage(
            title: args['title'],
            category: args['category'],
            color: args['color'],
          );
        },
        '/create-flashcard': (context) => CreateFlashcardPage(),
        '/study-mode': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StudyModePage(
            flashcards: args['flashcards'],
            title: args['title'],
            color: args['color'],
          );
        },
      },
    );
  }
}

//p dah bisa