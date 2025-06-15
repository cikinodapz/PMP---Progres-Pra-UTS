import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:efeflascard/api/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  late Future<List<dynamic>> _historyFuture;
  DateTime? _selectedDate;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 1; // Halaman saat ini
  final int _itemsPerPage = 10; // Batas 10 item per halaman

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService().getHistory();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8A2BE2),
              onPrimary: Colors.white,
              surface: Color(0xFF1C2526),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey.shade900.withOpacity(0.9),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _currentPage = 1; // Reset ke halaman 1 saat filter berubah
        _historyFuture = ApiService().getHistory(date: _selectedDate);
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _currentPage = 1; // Reset ke halaman 1
      _historyFuture = ApiService().getHistory();
    });
  }

  void _showDetailDialog(BuildContext context, dynamic item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, anim1, anim2) {
        return _HistoryDetailDialog(item: item);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage(int totalItems) {
    if (_currentPage < (totalItems / _itemsPerPage).ceil()) {
      setState(() {
        _currentPage++;
      });
    }
  }

  Widget _buildContent(
    BuildContext context,
    AsyncSnapshot<List<dynamic>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: _LoadingWidget());
    }
    if (snapshot.hasError) {
      return _ErrorWidget(
        error: snapshot.error.toString(),
        onRetry:
            () => setState(() {
              _historyFuture = ApiService().getHistory();
            }),
      );
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(child: _EmptyStateWidget(selectedDate: _selectedDate));
    }

    List<dynamic> filteredData =
        _selectedDate == null
            ? snapshot.data!
            : snapshot.data!.where((item) {
              DateTime itemDate = DateTime.parse(item['createdAt']).toLocal();
              return itemDate.year == _selectedDate!.year &&
                  itemDate.month == _selectedDate!.month &&
                  itemDate.day == _selectedDate!.day;
            }).toList();

    if (filteredData.isEmpty) {
      return Center(child: _EmptyStateWidget(selectedDate: _selectedDate));
    }

    // Hitung item yang akan ditampilkan berdasarkan halaman saat ini
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > filteredData.length) {
      endIndex = filteredData.length;
    }
    List<dynamic> paginatedData = filteredData.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
              'Quiz History',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 800.ms,
            ),
        const SizedBox(height: 12),
        Text(
          'Tap a card to view details of your past quiz attempts',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 20),
        ...paginatedData.asMap().entries.map(
          (entry) => GestureDetector(
            onTap: () => _showDetailDialog(context, entry.value),
            child: _HistoryItemWidget(index: entry.key, item: entry.value),
          ),
        ),
        const SizedBox(height: 20),
        // Tombol navigasi pagination
        // Replace the existing pagination Row widget in the _buildContent method with this:
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous Page Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    _currentPage > 1
                        ? const Color(0xFF8A2BE2).withOpacity(0.8)
                        : Colors.grey.shade800,
                boxShadow:
                    _currentPage > 1
                        ? [
                          BoxShadow(
                            color: const Color(0xFF8A2BE2).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, size: 28),
                color: Colors.white,
                onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                tooltip: 'Previous Page',
              ),
            ),

            // Page Indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(
                '$_currentPage / ${(filteredData.length / _itemsPerPage).ceil()}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Next Page Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color:
                    _currentPage < (filteredData.length / _itemsPerPage).ceil()
                        ? const Color(0xFF8A2BE2).withOpacity(0.8)
                        : Colors.grey.shade800,
                boxShadow:
                    _currentPage < (filteredData.length / _itemsPerPage).ceil()
                        ? [
                          BoxShadow(
                            color: const Color(0xFF8A2BE2).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                        : null,
              ),
              child: IconButton(
                icon: const Icon(Icons.chevron_right, size: 28),
                color: Colors.white,
                onPressed:
                    _currentPage < (filteredData.length / _itemsPerPage).ceil()
                        ? () => _goToNextPage(filteredData.length)
                        : null,
                tooltip: 'Next Page',
              ),
            ),
          ],
        ),
      ],
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
              const Color(0xFF8A2BE2).withOpacity(0.3),
              Colors.grey.shade900.withOpacity(0.8),
              Colors.black87.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: FutureBuilder<List<dynamic>>(
                    future: _historyFuture,
                    builder: _buildContent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title:
            _selectedDate == null
                ? Text(
                  'Quiz Vault',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 28,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                )
                : Text(
                  '${_selectedDate!.toString().split(' ')[0]}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF8A2BE2).withOpacity(0.7),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.white, size: 28),
          onPressed: () => _pickDate(context),
          tooltip: 'Filter by Date',
        ),
        if (_selectedDate != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.redAccent, size: 28),
            onPressed: _clearDateFilter,
            tooltip: 'Clear Date Filter',
          ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Widget untuk tombol pagination
class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const _PaginationButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: onPressed != null ? Colors.white : Colors.grey.shade600,
        size: 28,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade900.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const CircularProgressIndicator(
        color: Color(0xFF8A2BE2),
        strokeWidth: 4,
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade900.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms),
        const SizedBox(height: 24),
        _RetryButton(onRetry: onRetry),
      ],
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  final DateTime? selectedDate;

  const _EmptyStateWidget({this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade900.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.grey, size: 48),
          const SizedBox(height: 16),
          Text(
            selectedDate == null
                ? 'No quiz history found.'
                : 'No history for ${selectedDate!.toString().split(' ')[0]}.',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;

  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFF7241D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A2BE2).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          'Retry',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }
}

class _HistoryItemWidget extends StatelessWidget {
  final int index;
  final dynamic item;

  const _HistoryItemWidget({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(item['createdAt']).toLocal();
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade900.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['question'],
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          item['isCorrect'] ? Icons.check_circle : Icons.cancel,
                          color:
                              item['isCorrect']
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow(
                      'Deck',
                      '${item['deckName']} (${item['deckCategory']})',
                    ),
                    _buildStatRow('Date', formattedDate),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (400 + index * 100).ms)
        .slideY(
          begin: 0.2,
          end: 0,
          curve: Curves.easeOutCubic,
          duration: 800.ms,
        );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: color ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDetailDialog extends StatelessWidget {
  final dynamic item;

  const _HistoryDetailDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.parse(item['createdAt']).toLocal();
    final formattedDate =
        '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Center(
      child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade900.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A2BE2).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Quiz Details',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Question',
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['question'] ?? 'N/A',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Your Answer',
                          item['userAnswer'] ?? 'N/A',
                          color: Colors.white,
                        ),
                        _buildStatRow(
                          'Correct Answer',
                          item['correctAnswer'] ?? 'N/A',
                          color: Colors.greenAccent,
                        ),
                        _buildStatRow(
                          'Deck',
                          '${item['deckName'] ?? 'N/A'} (${item['deckCategory'] ?? 'N/A'})',
                        ),
                        _buildStatRow(
                          'Status',
                          item['status'] ?? 'N/A',
                          color:
                              item['isCorrect']
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                        ),
                        _buildStatRow('Date', formattedDate),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 400.ms)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            curve: Curves.easeOutBack,
            duration: 400.ms,
          ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
