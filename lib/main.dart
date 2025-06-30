import 'package:efeflascard/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screen/login_page.dart';
import 'screen/register_page.dart';
import 'screen/home_page.dart';
import 'screen/profile_page.dart';
import 'screen/history_page.dart';
import 'screen/favorites_page.dart';
import 'screen/create_flashcard_page.dart';
import 'screen/study_mode_page.dart';
import 'screen/splash_screen.dart';

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/notification_icon');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Message notification: ${message.notification}');
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification?.title,
          message.notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@drawable/notification_icon',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlashCard App',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade900,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.purpleAccent,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainPage(),
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
          print("unknowasd");
          return MaterialPageRoute(builder: (context) => const MainPage());
        }
        return null;
      },
      onUnknownRoute: (settings) {
        print("unknow");
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
    const FavoritesPage(),
    const ProfilePage(),
  ];

  static final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.dashboard, label: 'Home', tooltip: 'Dashboard'),
    NavigationItem(
      icon: Icons.history,
      label: 'History',
      tooltip: 'Riwayat Belajar',
    ),
    NavigationItem(
      icon: Icons.favorite,
      label: 'Favorites',
      tooltip: 'Favorite Decks',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Profile',
      tooltip: 'Profil Pengguna',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool get _isWebLayout {
    return MediaQuery.of(context).size.width >= 768;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isWebLayout ? _buildWebLayout() : _buildMobileLayout(),
      bottomNavigationBar: !_isWebLayout ? _buildBottomNavigation() : null,
    );
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border(
              right: BorderSide(color: Colors.grey.shade800, width: 1),
            ),
          ),
          child: Column(
            children: [
              const Divider(
                color: Color(0xFF2A2A2A),
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _navigationItems.length,
                  itemBuilder: (context, index) {
                    final item = _navigationItems[index];
                    final isSelected = _selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.deepPurple.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Icon(
                            item.icon,
                            color: isSelected
                                ? Colors.deepPurple
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          title: Text(
                            item.label,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.grey.shade300,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          onTap: () => _onItemTapped(index),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          tileColor: Colors.transparent,
                          hoverColor: Colors.grey.shade800.withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF2A2A2A), width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FlashCard App',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0 • © 2025',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF121212),
            child: _pages[_selectedIndex],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _pages[_selectedIndex];
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      items: _navigationItems.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
          tooltip: item.tooltip,
        );
      }).toList(),
      currentIndex: _selectedIndex,
      selectedItemColor: const Color(0xFF8A2BE2),
      unselectedItemColor: Colors.grey.shade400,
      backgroundColor: Colors.grey.shade900,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.poppins(),
      onTap: _onItemTapped,
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String tooltip;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.tooltip,
  });
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

// static const String _baseUrlMobile =
      // 'http://10.0.2.2:3000'; // For Android emulator
      // 'http://192.168.18.66:3000'; // For POCO
      // 'http://192.168.100.117:3000'; // For POCO baarasobadan

  // 'http://backend.smartflash.my.id'; //for Production

  // static const String _baseUrlWeb = 'http://localhost:3000'; // For web
  // static const String _baseUrlWeb = 'http://192.168.18.66:3000'; // For POCO
  // static const String _baseUrlWeb = 'http://backend.smartflash.my.id'; //for prod