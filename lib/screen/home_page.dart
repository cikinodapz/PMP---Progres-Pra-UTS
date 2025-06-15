import 'dart:ui';

import 'package:efeflascard/screen/create_flashcard_page.dart';
import 'package:efeflascard/screen/edit_deck_page.dart';
import 'package:efeflascard/screen/flashcard_set_detail_page.dart';
import 'package:efeflascard/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Future<List<Map<String, dynamic>>>? _decksFuture;
  final ApiService apiService = ApiService();
  late AnimationController _animationController;
  late Animation<double> _searchAnimation;
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _categoryIcons = [
    {'name': 'All', 'icon': Icons.notes, 'isSelected': true},
  ];
  int _selectedCategoryIndex = 0;
  List<Animation<double>> _cardAnimations = [];

  final List<List<Color>> _gradients = [
    [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
    [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
    [const Color(0xFFFF8008), const Color(0xFFFFC837)],
    [const Color(0xFF396afc), const Color(0xFF2948ff)],
    [const Color(0xFFf83600), const Color(0xFFf9d423)],
  ];

  String _sortOption = 'Newest'; // Default sort option
  final List<String> _sortOptions = [
    'Newest',
    'Oldest',
    'Most Mastered',
    'In Progress',
  ];

  // Add this method to sort decks
  List<Map<String, dynamic>> _sortDecks(List<Map<String, dynamic>> decks) {
    final sortedDecks = List<Map<String, dynamic>>.from(decks);

    switch (_sortOption) {
      case 'Newest':
        sortedDecks.sort(
          (a, b) => DateTime.parse(
            b['createdAt'],
          ).compareTo(DateTime.parse(a['createdAt'])),
        );
        break;
      case 'Oldest':
        sortedDecks.sort(
          (a, b) => DateTime.parse(
            a['createdAt'],
          ).compareTo(DateTime.parse(b['createdAt'])),
        );
        break;
      case 'Most Mastered':
        sortedDecks.sort((a, b) {
          // Prioritize decks with highest percentage first
          final aPercent = a['percentage'] ?? 0;
          final bPercent = b['percentage'] ?? 0;
          return bPercent.compareTo(aPercent);
        });
        break;
      case 'In Progress':
        sortedDecks.sort((a, b) {
          // Prioritize decks that are in progress (0% < progress < 100%)
          final aProgress =
              (a['percentage'] ?? 0) > 0 && (a['percentage'] ?? 0) < 100;
          final bProgress =
              (b['percentage'] ?? 0) > 0 && (b['percentage'] ?? 0) < 100;

          if (aProgress && !bProgress) return -1;
          if (!aProgress && bProgress) return 1;

          // If both are in progress or both are not, sort by percentage
          final aPercent = a['percentage'] ?? 0;
          final bPercent = b['percentage'] ?? 0;
          return bPercent.compareTo(aPercent);
        });
        break;
    }
    return sortedDecks;
  }

  @override
  void initState() {
    super.initState();
    _decksFuture = Future.value([]);
    _checkTokenAndFetchDecks();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
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
      print('Fetched decks: $decksData'); // Log untuk debug

      // Convert each deck to Map<String, dynamic> and ensure all fields are present
      final List<Map<String, dynamic>> decks =
          decksData.map<Map<String, dynamic>>((deck) {
            return {
              'id': deck['id'] ?? '',
              'name': deck['name'] ?? 'Untitled Deck',
              'category': deck['category'] ?? 'Uncategorized',
              'createdAt':
                  deck['createdAt'] ?? DateTime.now().toIso8601String(),
              'flashcardCount': deck['flashcardCount'] ?? 0,
              'mastered': deck['mastered'] ?? 0,
              'percentage': deck['percentage'] ?? 0, // Add percentage from API
            };
          }).toList();

      // Rest of your existing code...
      final categories =
          decks
              .map((deck) => deck['category']?.toString() ?? 'Uncategorized')
              .toSet()
              .toList();

      _categoryIcons = [
        {
          'name': 'All',
          'icon': Icons.notes,
          'isSelected': _selectedCategoryIndex == 0,
        },
        ...categories.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final category = entry.value;
          return {
            'name': category,
            'icon': _getCategoryIcon(category),
            'isSelected': _selectedCategoryIndex == index,
          };
        }),
      ];

      // Rest of your existing animation setup...
      setState(() {
        _cardAnimations = List.generate(
          decks.length,
          (index) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Interval((index * 0.1), 1.0, curve: Curves.easeOutCubic),
            ),
          ),
        );
      });

      _animationController.forward();
      return decks;
    } catch (e) {
      print('Error fetching decks: $e');
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
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF8A2BE2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
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
      _selectedCategoryIndex = index;
      _decksFuture = _fetchDecks(); // Refresh data
      _animationController.reset();
      _animationController.forward();
    });
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
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF8A2BE2).withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/flashgo_upgrade.png',
                              width: 99, // Sesuaikan ukuran agar proporsional
                              height: 99,
                              fit:
                                  BoxFit
                                      .contain, // Pastikan gambar tidak terdistorsi
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'FlashGo',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isSearchExpanded ? Icons.close : Icons.search,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: _toggleSearch,
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8A2BE2),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: const Text(
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
                  ),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizeTransition(
                      sizeFactor: _searchAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade700.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search flashcards...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            suffixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          cursorColor: const Color(0xFF8A2BE2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
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
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFF8A2BE2)
                                              : Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF8A2BE2,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                              : [],
                                    ),
                                    child: Icon(
                                      category['icon'] as IconData,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade400,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['name'] as String,
                                    style: GoogleFonts.poppins(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade400,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildStatisticCards(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Flashcards',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortOption,
                            icon: Icon(
                              Icons.sort,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            dropdownColor: Colors.grey.shade900,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortOption = newValue;
                                  _decksFuture = _fetchDecks();
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              }
                            },
                            items:
                                _sortOptions.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight:
                                            value == _sortOption
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: _buildDecksList(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  // Helper method to filter decks based on category and search query
  List<Map<String, dynamic>> _filterDecks(List<Map<String, dynamic>> decks) {
    var filteredDecks =
        _searchQuery.isEmpty
            ? decks
            : decks
                .where(
                  (deck) =>
                      deck['name'].toString().toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      (deck['category']?.toString().toLowerCase() ??
                              'uncategorized')
                          .contains(_searchQuery.toLowerCase()),
                )
                .toList();

    if (_selectedCategoryIndex != 0) {
      final selectedCategory =
          _categoryIcons[_selectedCategoryIndex]['name'] as String;
      filteredDecks.retainWhere(
        (deck) =>
            (deck['category']?.toString().toLowerCase() ?? 'uncategorized') ==
            selectedCategory.toLowerCase(),
      );
    }

    return filteredDecks;
  }

  Widget _buildStatisticCards() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _decksFuture,
      builder: (context, snapshot) {
        int totalSets = 0;
        int inProgress = 0;
        int mastered = 0;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final filteredDecks = _filterDecks(snapshot.data!);
          totalSets = filteredDecks.length;
          inProgress =
              filteredDecks.where((deck) {
                final percent = deck['percentage'] ?? 0;
                return percent > 0 && percent < 100;
              }).length;
          mastered =
              filteredDecks.where((deck) {
                final percent = deck['percentage'] ?? 0;
                return percent == 100;
              }).length;
        }

        final ValueNotifier<int?> touchedIndex = ValueNotifier<int?>(null);

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            height: 200, // Further reduced height
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.25), // More transparent
                  Colors.deepPurple.shade900.withOpacity(0.2),
                  Colors.purpleAccent.shade700.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), // Softer blur
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05), // Very subtle overlay
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 4, // Increased flex to give pie chart more space
                      child: Padding(
                        padding: const EdgeInsets.all(12), // Reduced padding
                        child: ValueListenableBuilder<int?>(
                          valueListenable: touchedIndex,
                          builder: (context, value, child) {
                            return AnimatedScale(
                              scale: value != null ? 1.02 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: PieChart(
                                PieChartData(
                                  pieTouchData: PieTouchData(
                                    touchCallback: (
                                      FlTouchEvent event,
                                      pieTouchResponse,
                                    ) {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        touchedIndex.value = null;
                                        return;
                                      }
                                      touchedIndex.value =
                                          pieTouchResponse
                                              .touchedSection!
                                              .touchedSectionIndex;
                                    },
                                  ),
                                  borderData: FlBorderData(show: false),
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 40, // Further reduced
                                  startDegreeOffset: -90,
                                  sections: [
                                    PieChartSectionData(
                                      color: Colors.white.withOpacity(0.95),
                                      value: totalSets.toDouble(),
                                      title: totalSets > 0 ? '$totalSets' : '',
                                      radius: value == 0 ? 60 : 50,
                                      titleStyle: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    360
                                                ? 12
                                                : 14,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      badgeWidget:
                                          value == 0
                                              ? _buildBadge(
                                                'Total: $totalSets',
                                                Colors.white.withOpacity(0.95),
                                                true,
                                              )
                                              : null,
                                      badgePositionPercentageOffset: 0.65,
                                    ),
                                    PieChartSectionData(
                                      color: const Color(0xFFBB86FC),
                                      value: inProgress.toDouble(),
                                      title:
                                          inProgress > 0 ? '$inProgress' : '',
                                      radius: value == 1 ? 60 : 50,
                                      titleStyle: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    360
                                                ? 11
                                                : 13,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      badgeWidget:
                                          value == 1
                                              ? _buildBadge(
                                                'In Progress: $inProgress',
                                                const Color(0xFFBB86FC),
                                                true,
                                              )
                                              : null,
                                      badgePositionPercentageOffset: 0.65,
                                    ),
                                    PieChartSectionData(
                                      color: const Color(0xFF8A2BE2),
                                      value: mastered.toDouble(),
                                      title: mastered > 0 ? '$mastered' : '',
                                      radius: value == 2 ? 60 : 50,
                                      titleStyle: GoogleFonts.poppins(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    360
                                                ? 10
                                                : 12,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 3,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      badgeWidget:
                                          value == 2
                                              ? _buildBadge(
                                                'Mastered: $mastered',
                                                const Color(0xFF8A2BE2),
                                                true,
                                              )
                                              : null,
                                      badgePositionPercentageOffset: 0.65,
                                    ),
                                  ],
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 400,
                                ),
                                swapAnimationCurve: Curves.easeInOutQuint,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Legend
                    Expanded(
                      flex: 3, // Reduced flex to balance space
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 6,
                        ),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _buildLegendItem(
                                'Total Sets',
                                Colors.white.withOpacity(0.95),
                                '$totalSets',
                                Icons.library_books,
                                context,
                              ),
                              _buildLegendItem(
                                'In Progress',
                                const Color(0xFFBB86FC),
                                '$inProgress',
                                Icons.pending_actions,
                                context,
                              ),
                              _buildLegendItem(
                                'Mastered',
                                const Color(0xFF8A2BE2),
                                '$mastered',
                                Icons.star,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String title, Color color, bool isTouched) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ), // Smaller badge
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: isTouched ? 8 : 4,
            spreadRadius: isTouched ? 0.5 : 0,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: isTouched ? Colors.white.withOpacity(0.6) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 1,
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLegendItem(
    String title,
    Color color,
    String value,
    IconData icon,
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withOpacity(0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18, // Smaller icon
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(child: Icon(icon, size: 10, color: Colors.black87)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$value ${title == 'Total Sets' ? 'sets' : 'decks'}',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: MediaQuery.of(context).size.width < 360 ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 60,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildDecksList() {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _decksFuture,
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
                      Icons.add_card,
                      color: Colors.grey.shade400,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No flashcard sets yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first flashcard set',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateFlashcardPage(),
                        ),
                      ).then((_) {
                        setState(() {
                          _decksFuture = _fetchDecks();
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Create New Set',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2BE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    'Failed to load decks',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _decksFuture = _fetchDecks();
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
                      Icons.add_card,
                      color: Colors.grey.shade400,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No flashcard sets yet',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first flashcard set',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateFlashcardPage(),
                        ),
                      ).then((_) {
                        setState(() {
                          _decksFuture = _fetchDecks();
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Create New Set',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A2BE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Update the _buildDecksList method: replace the filteredDecks assignment with this
          final decks = snapshot.data!;
          final filteredDecks =
              _searchQuery.isEmpty
                  ? decks
                  : decks
                      .where(
                        (deck) =>
                            deck['name'].toString().toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            (deck['category']?.toString().toLowerCase() ??
                                    'uncategorized')
                                .contains(_searchQuery.toLowerCase()),
                      )
                      .toList();

          if (_selectedCategoryIndex != 0) {
            final selectedCategory =
                _categoryIcons[_selectedCategoryIndex]['name'] as String;
            filteredDecks.retainWhere(
              (deck) =>
                  (deck['category']?.toString().toLowerCase() ??
                      'uncategorized') ==
                  selectedCategory.toLowerCase(),
            );
          }
          final sortedDecks = _sortDecks(filteredDecks);

          print('Filtered decks: $filteredDecks'); // Log untuk debug

          if (filteredDecks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, color: Colors.grey, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    _selectedCategoryIndex == 0
                        ? 'No matches found'
                        : 'No decks in "${_categoryIcons[_selectedCategoryIndex]['name']}"',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different category or create a new deck',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          _animationController.reset();
          _animationController.forward();

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedDecks.length,
            itemBuilder: (context, index) {
              final deck = sortedDecks[index];
              final gradientPair = _gradients[index % _gradients.length];
              final animation = Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1),
                    1.0,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              );

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
                        builder:
                            (context) => EditDeckPage(
                              deckId: deck['id'],
                              name: deck['name'],
                              category: deck['category'],
                            ),
                      ),
                    );
                    setState(() {
                      _decksFuture = _fetchDecks();
                    });
                    return false;
                  } else {
                    return await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            backgroundColor: Colors.grey.shade900.withOpacity(
                              0.95,
                            ),
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
                    builder:
                        (context) => FlashcardSetDetailPage(
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
                              Text(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Enhanced Category Display
                              GestureDetector(
                                onTap: () {
                                  // Optional: Add a subtle animation or action
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
                                        color: gradientColors[0].withOpacity(
                                          0.4,
                                        ),
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
                        const SizedBox(width: 16),
                        Icon(Icons.star, color: Colors.grey.shade400, size: 16),
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
                                  backgroundColor: Colors.grey.shade800
                                      .withOpacity(0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey.shade900,
                                  ),
                                  minHeight: 10,
                                ),
                                LinearProgressIndicator(
                                  value: percentageValue,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    gradientColors[0],
                                  ),
                                  minHeight: 10,
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
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      CreateFlashcardPage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;
                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _decksFuture = _fetchDecks();
              });
            }
          });
        },
        splashColor: Colors.white.withOpacity(0.3),
        highlightColor: const Color(0xFF8A2BE2).withOpacity(0.2),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF8A2BE2),
                const Color(0xFF8A2BE2).withOpacity(0.7),
              ],
              stops: const [0.0, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: const Color(0xFF8A2BE2).withOpacity(0.3),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.add,
            size: 36,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(1, 1),
              ),
            ],
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
