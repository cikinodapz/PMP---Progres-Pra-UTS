import 'package:efeflascard/screen/create_flashcard_page.dart';
import 'package:efeflascard/screen/edit_deck_page.dart';
import 'package:efeflascard/screen/flashcard_set_detail_page.dart';
import 'package:efeflascard/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? _decksFuture;
  final ApiService apiService = ApiService();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categoryIcons = [
    {
      'name': 'All',
      'icon': Icons.notes,
      'isSelected': true,
    },
    {
      'name': 'Languages',
      'icon': Icons.language,
      'isSelected': false,
    },
    {
      'name': 'Science',
      'icon': Icons.science,
      'isSelected': false,
    },
    {
      'name': 'Math',
      'icon': Icons.calculate,
      'isSelected': false,
    },
    {
      'name': 'History',
      'icon': Icons.history_edu,
      'isSelected': false,
    },
  ];

 final List<List<Color>> _gradients = [
  [Color(0xFF7F00FF), Color(0xFFE100FF)], // Purple to Pink
  [Color(0xFF00C9FF), Color(0xFF92FE9D)], // Blue to Green
  [Color(0xFFFF8008), Color(0xFFFFC837)], // Orange to Yellow
  [Color(0xFF396afc), Color(0xFF2948ff)], // Blue to Indigo
  [Color(0xFFf83600), Color(0xFFf9d423)], // Red to Yellow
];

  @override
  void initState() {
    super.initState();
    _decksFuture = Future.value([]);
    _checkTokenAndFetchDecks();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkTokenAndFetchDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    setState(() {
      _decksFuture = _fetchDecks();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchDecks() async {
    try {
      final decksData = await apiService.getAllDecks();
      return List<Map<String, dynamic>>.from(decksData);
    } catch (e) {
      if (mounted) {
        _showSnackbar('Failed to load decks: $e', isError: true);
      }
      return [];
    }
  }

  Future<void> _deleteDeck(String deckId) async {
    try {
      final response = await apiService.deleteDeck(deckId);
      if (mounted) {
        _showSnackbar(response['message']);
        setState(() {
          _decksFuture = _fetchDecks();
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Failed to delete deck: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearchExpanded = !_isSearchExpanded;
      if (_isSearchExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _selectCategory(int index) {
    setState(() {
      for (int i = 0; i < _categoryIcons.length; i++) {
        _categoryIcons[i]['isSelected'] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF191930), Color(0xFF0F0F1B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                SizedBox(height: 16),
                _buildAnimatedSearchBar(),
                SizedBox(height: 20),
                _buildCategoryList(),
                SizedBox(height: 24),
                _buildStatisticCards(),
                SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Flashcards',
                        style: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.sort, color: Colors.white70, size: 18),
                        label: Text(
                          'Sort',
                          style: TextStyle(color: Colors.white70),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                _buildDecksList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF8A2BE2),
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(10),
                child: Icon(Icons.auto_stories, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                'FlashGo',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(_isSearchExpanded ? Icons.close : Icons.search, color: Colors.white),
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.notifications_outlined, color: Colors.white),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Color(0xFF8A2BE2),
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSearchBar() {
    return SizeTransition(
      sizeFactor: _animation,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search flashcards...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          cursorColor: Color(0xFF8A2BE2),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoryIcons.length,
        itemBuilder: (context, index) {
          final category = _categoryIcons[index];
          final isSelected = category['isSelected'] as bool;
          
          return GestureDetector(
            onTap: () => _selectCategory(index),
            child: Container(
              width: 80,
              margin: EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF8A2BE2) : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(0xFF8A2BE2).withOpacity(0.4),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticCards() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFF7241D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8A2BE2).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Total Sets', '12', Icons.library_books),
          _buildVerticalDivider(),
          _buildStatItem('In Progress', '3', Icons.pending_actions),
          _buildVerticalDivider(),
          _buildStatItem('Mastered', '5', Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildDecksList() {
    return Expanded(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _decksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8A2BE2)),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load decks',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _decksFuture = _fetchDecks();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8A2BE2),
                    ),
                    child: Text('Try Again'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_card, color: Colors.white70, size: 60),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No flashcard sets yet',
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your first flashcard set',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateFlashcardPage()),
                      ).then((_) {
                        setState(() {
                          _decksFuture = _fetchDecks();
                        });
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Create New Set'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8A2BE2),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final decks = snapshot.data!;
          final filteredDecks = _searchQuery.isEmpty
              ? decks
              : decks.where((deck) =>
                  deck['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  deck['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          if (filteredDecks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, color: Colors.white70, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'No matches found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.only(bottom: 80),
            itemCount: filteredDecks.length,
            itemBuilder: (context, index) {
              final deck = filteredDecks[index];
              final gradientPair = _gradients[index % _gradients.length];
              
              // Random progress for visualization (replace with actual progress data)
              final progress = index / decks.length;
              
              return _buildDeckCard(deck, gradientPair as List<Color>, progress);
            },
          );
        },
      ),
    );
  }

  Widget _buildDeckCard(
    Map<String, dynamic> deck,
    List<Color> gradientColors,
    double progress,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlashcardSetDetailPage(
                  deckId: deck['id'],
                  title: deck['name'],
                  category: deck['category'],
                  color: gradientColors[0],
                ),
              ),
            ).then((_) {
              setState(() {
                _decksFuture = _fetchDecks();
              });
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(deck['category']),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck['name'],
                            style: GoogleFonts.poppins(
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: gradientColors,
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  deck['category'],
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.access_time, color: Colors.white70, size: 14),
                              SizedBox(width: 4),
                              Text(
                                _formatDate(deck['createdAt']),
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white70),
                      color: Color(0xFF2A2A40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.white70, size: 18),
                              SizedBox(width: 8),
                              Text('Edit', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDeckPage(
                                deckId: deck['id'],
                                name: deck['name'],
                                category: deck['category'],
                              ),
                            ),
                          );
                          setState(() {
                            _decksFuture = _fetchDecks();
                          });
                        } else if (value == 'delete') {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Color(0xFF2A2A40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                'Delete Set',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${deck['name']}"?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteDeck(deck['id']);
                                  },
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.auto_stories, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '24 cards',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.timer, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '~15 min',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(gradientColors[0]),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: gradientColors[0],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFF7241D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8A2BE2).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => CreateFlashcardPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);
                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
            setState(() {
              _decksFuture = _fetchDecks();
            });
          },
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'languages':
        return Icons.language;
      case 'science':
        return Icons.science;
      case 'math':
        return Icons.calculate;
      case 'history':
        return Icons.history_edu;
      case 'programming':
        return Icons.code;
      case 'arts':
        return Icons.palette;
      case 'business':
        return Icons.business;
      default:
        return Icons.menu_book;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}