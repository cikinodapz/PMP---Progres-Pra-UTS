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

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService().getHistory();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuint,
    );
    _animationController.forward();
  }

  // Di bagian _pickDate, ubah kode menjadi:
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
              primary: Color(0xFF6B46C1),
              onPrimary: Colors.white,
              surface: Colors.black87,
              onSurface: Colors.white70,
            ),
            dialogBackgroundColor: Colors.black.withOpacity(0.9),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.cyanAccent),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Jika API mendukung filter tanggal
        _historyFuture = ApiService().getHistory(date: _selectedDate);
      });
    }
  }

  // Jika Anda perlu memfilter di sisi klien:
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

    // Filter data berdasarkan tanggal yang dipilih (jika ada)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
              'History Overview',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              curve: Curves.easeOutCubic,
              duration: 600.ms,
            ),
        const SizedBox(height: 8),
        Text(
          'Review your past quiz attempts',
          style: GoogleFonts.poppins(
            color: Colors.grey.shade300,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 16),
        ...filteredData.asMap().entries.map(
          (entry) => _HistoryItemWidget(index: entry.key, item: entry.value),
        ),
      ],
    );
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _historyFuture = ApiService().getHistory();
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
            colors: [
              const Color(0xFF6B46C1).withOpacity(0.4),
              Colors.black.withOpacity(0.9),
              Colors.black,
            ],
            stops: const [0.0, 0.6, 1.0],
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
                    horizontal: 16,
                    vertical: 12, // Reduced vertical padding
                  ),
                  child: FutureBuilder<List<dynamic>>(
                    future: _historyFuture,
                    builder:
                        (context, snapshot) => _buildContent(context, snapshot),
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
      expandedHeight: 100, // Further reduced height for a compact look
      floating: false,
      pinned: true,
      backgroundColor: Colors.black.withOpacity(0.2),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        title:
            _selectedDate == null
                ? Text(
                  'History',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
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
                )
                : Text(
                  '${_selectedDate!.toString().split(' ')[0]}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 20,
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
                const Color(0xFF6B46C1).withOpacity(0.6),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: Colors.cyanAccent),
          onPressed: () => _pickDate(context),
          tooltip: 'Filter by Date',
        ),
        if (_selectedDate != null)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.redAccent),
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

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const CircularProgressIndicator(
        color: Color(0xFF6B46C1),
        strokeWidth: 4,
      ),
    ).animate().scale(duration: 500.ms, curve: Curves.easeInOut);
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
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Error: $error',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 16),
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
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          Text(
            selectedDate == null
                ? 'No history found.'
                : 'No history found for ${selectedDate!.toString().split(' ')[0]}.',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade300,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B46C1).withOpacity(0.3),
              blurRadius: 12,
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
    ).animate().scale(duration: 500.ms, curve: Curves.easeInOut);
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
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
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
                    Text(
                      item['question'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow('Your Answer', item['userAnswer']),
                    _buildStatRow('Correct Answer', item['correctAnswer']),
                    _buildStatRow(
                      'Deck',
                      '${item['deckName']} (${item['deckCategory']})',
                    ),
                    _buildStatRow(
                      'Status',
                      item['status'],
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
        )
        .animate()
        .fadeIn(delay: (400 + index * 150).ms)
        .slideY(
          begin: 0.2,
          end: 0,
          curve: Curves.easeOutQuint,
          duration: 700.ms,
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: color ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
