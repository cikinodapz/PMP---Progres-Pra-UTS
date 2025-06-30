import 'dart:ui';
import 'package:efeflascard/api/api_service.dart';
import 'package:efeflascard/screen/edit_deck_page.dart';
import 'package:efeflascard/screen/flashcard_set_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _favoritesFuture;
  final ApiService apiService = ApiService();
  late AnimationController _animationController;
  List<Animation<double>> _cardAnimations = [];

  final List<List<Color>> _gradients = [
    [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
    [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
    [const Color(0xFFFF8008), const Color(0xFFFFC837)],
    [const Color(0xFF396afc), const Color(0xFF2948ff)],
    [const Color(0xFFf83600), const Color(0xFFf9d423)],
  ];

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _fetchFavorites();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchFavorites() async {
    try {
      final favoritesData = await apiService.getFavorites();
      final List<Map<String, dynamic>> favorites =
          favoritesData.map<Map<String, dynamic>>((deck) {
        return {
          'id': deck['id'] ?? '',
          'name': deck['name'] ?? 'Untitled Deck',
          'category': deck['category'] ?? 'Uncategorized',
          'createdAt': deck['createdAt'] ?? DateTime.now().toIso8601String(),
          'flashcardCount': deck['flashcardCount'] ?? 0,
          'mastered': deck['mastered'] ?? 0,
          'percentage': deck['percentage'] ?? 0,
          'isFavorite': true,
        };
      }).toList();

      setState(() {
        _cardAnimations = List.generate(
          favorites.length,
          (index) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval((index * 0.1), 1.0, curve: Curves.easeOutCubic),
            ),
          ),
        );
      });

      _animationController.forward();
      return favorites;
    } catch (e) {
      if (mounted) {
        _showSnackbar('Failed to load favorite decks: $e', isError: true);
      }
      return [];
    }
  }

  Future<void> _toggleFavorite(String deckId, String deckName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Remove from Favorites',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Remove "$deckName" from your favorites?',
          style: GoogleFonts.poppins(color: Colors.grey.shade300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey.shade400),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await apiService.toggleFavorite(deckId);
        if (mounted) {
          _showSnackbar(response['message']);
          setState(() {
            _favoritesFuture = _fetchFavorites();
          });
        }
      } catch (e) {
        if (mounted) {
          _showSnackbar('Failed to toggle favorite: $e', isError: true);
        }
      }
    }
  }

  Future<void> _deleteDeck(String deckId) async {
    try {
      final response = await apiService.deleteDeck(deckId);
      if (mounted) {
        _showSnackbar(response['message']);
        setState(() {
          _favoritesFuture = _fetchFavorites();
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
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF191930),
            Colors.grey.shade900,
            Colors.black87,
          ],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Favorite Decks',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.4),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Your top picks, always ready',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF8A2BE2).withOpacity(0.8),
                      const Color(0xFF4B0082).withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            sliver: _buildFavoritesList(),
          ),
        ],
      ),
    )
    );
  }

  Widget _buildFavoritesList() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.grey.shade400,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No favorite decks yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some decks to your favorites',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load favorite decks',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _favoritesFuture = _fetchFavorites();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2BE2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.grey.shade400,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No favorite decks yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some decks to your favorites',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final favorites = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final deck = favorites[index];
              final gradientPair = _gradients[index % _gradients.length];
              final animation = _cardAnimations[index];

              return Dismissible(
                key: Key(deck['id']),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
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
                      _favoritesFuture = _fetchFavorites();
                    });
                    return false;
                  } else {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey.shade900.withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'Delete Set',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete "${deck['name']}"?',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    _deleteDeck(deck['id']);
                  }
                },
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: animation.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - animation.value) * 20),
                        child: child,
                      ),
                    );
                  },
                  child: _buildDeckCard(deck, gradientPair),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDeckCard(Map<String, dynamic> deck, List<Color> gradientColors) {
    final double percentageValue = (deck['percentage'] ?? 0) / 100;
    final AnimationController _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final Animation<double> _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    final AnimationController _favoriteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final Animation<double> _favoriteScale = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.easeInOut),
    );

    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade900.withOpacity(0.9), Colors.black87],
              stops: const [0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 3,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: gradientColors[0].withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
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
                    _favoritesFuture = _fetchFavorites();
                  });
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                gradientColors[0],
                                gradientColors[1].withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: gradientColors[0].withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(deck['category']),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      deck['name'],
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 6,
                                            color: Colors.black.withOpacity(0.3),
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      await _favoriteController.forward();
                                      await _toggleFavorite(deck['id'], deck['name']);
                                      _favoriteController.reverse();
                                    },
                                    child: ScaleTransition(
                                      scale: _favoriteScale,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              gradientColors[0].withOpacity(0.2),
                                              gradientColors[1].withOpacity(0.2),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.redAccent.withOpacity(0.4),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.favorite,
                                          color: Colors.redAccent,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Category: ${deck['category'] ?? 'Uncategorized'}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: gradientColors[0],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        gradientColors[0],
                                        gradientColors[1].withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradientColors[0].withOpacity(0.4),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(deck['category']),
                                        color: Colors.white.withOpacity(0.9),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        deck['category'] ?? 'Uncategorized',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.grey.shade400,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(deck['createdAt']),
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade400,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_stories,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${deck['flashcardCount']} cards',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${deck['mastered']} mastered',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Stack(
                              children: [
                                LinearProgressIndicator(
                                  value: percentageValue,
                                  backgroundColor: Colors.grey.shade800.withOpacity(0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey.shade900,
                                  ),
                                  minHeight: 8,
                                ),
                                LinearProgressIndicator(
                                  value: percentageValue,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    gradientColors[0],
                                  ),
                                  minHeight: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${deck['percentage']}%',
                          style: GoogleFonts.poppins(
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
        ),
      ),
    )..addListener(() {
      if (_controller.isCompleted) _controller.dispose();
      if (_favoriteController.isCompleted) _favoriteController.dispose();
    });
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

extension on MouseRegion {
  addListener(Null Function() param0) {}
}