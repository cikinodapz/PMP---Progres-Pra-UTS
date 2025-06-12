import 'package:efeflascard/screen/create_flashcard_page.dart';
import 'package:efeflascard/screen/study_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';
import 'screen/profile_page.dart';
import 'screen/history_page.dart';

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
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainPage(), // Main page with bottom navigation
        '/create-flashcard': (context) => const CreateFlashcardPage(),
        '/study-mode': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return StudyModePage(
            flashcards: args['flashcards'],
            title: args['title'],
            color: args['color'],
          );
        },
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (context) => const MainPage());
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history), // Icon for history
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF8A2BE2),
        unselectedItemColor: Colors.grey.shade400,
        backgroundColor: Colors.grey.shade900,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(),
        onTap: _onItemTapped,
      ),
    );
  }
}

//dah bisa tadi
//dah sampe nampilin flashcard pada deck ya!!!!
//dah tampil gambarnya yeye tanpa bikin api baru
//dah bisa tambah flashcard
//sampai perbaiki tampilan buat deck baru dan edit decknya
//dah sampai memperbaiki tampilan dan memmatchingkan serta dah bisa ke website 
//dah bisa nampilin visualisasi pake pie chart yuhuu
//nambah fitur utk copy card yang di tap ke deck tertentu DONE
//oke nice dah bisa copy and cut flashcard ya!!
//okeh nice dah ada navigasi, utk profile, riwayat hehe
