import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../api/api_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _statsData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
    _scaleController.repeat(reverse: true);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Assuming ApiService is correctly implemented
      final apiService = ApiService();
      final [profile, stats] = await Future.wait([
        apiService.getProfile(),
        apiService.getStats(),
      ]);
      if (mounted) {
        setState(() {
          _profileData = profile;
          _statsData = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
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
            SliverAppBar(
              expandedHeight: 250,
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
                          stops: const [0.0, 0.7],
                        ),
                      ),
                    ),
                    Center(
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF8A2BE2).withOpacity(0.3),
                                Colors.white.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8A2BE2).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                              _profileData?['name'] ?? 'Loading...',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 32,
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
                            .slideY(begin: 0.2, end: 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child:
                      _isLoading
                          ? _buildLoadingWidget()
                          : _errorMessage != null
                          ? _buildErrorWidget()
                          : _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade900.withOpacity(0.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A2BE2).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const CircularProgressIndicator(
                color: Color(0xFF8A2BE2),
                strokeWidth: 4,
              ),
            ),
          ),
        ),
      ),
    ).animate().scale();
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade900.withOpacity(0.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _fetchData,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: const Color(0xFF8A2BE2).withOpacity(0.3),
                width: 1,
              ),
            ),
            elevation: 0,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2BE2), Color(0xFF7241D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ).animate().scale(),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Overview',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 12),
        Text(
          'Your personal information and stats',
          style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 16),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        _buildProfileCard(),
        const SizedBox(height: 24),
        Text(
          'Your Stats',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 12),
        if (_statsData != null) _buildAccuracyGauge(),
        const SizedBox(height: 24),
        if (_statsData != null) _buildAttemptsChart(),
        const SizedBox(height: 24),
        if (_statsData != null &&
            _statsData!['recentDecks'] != null &&
            (_statsData!['recentDecks'] as List<dynamic>).isNotEmpty)
          _buildRecentDecks(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade900.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF8A2BE2).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Name', _profileData?['name'] ?? 'N/A'),
                Divider(color: Colors.white.withOpacity(0.2)),
                _buildStatRow('Email', _profileData?['email'] ?? 'N/A'),
                Divider(color: Colors.white.withOpacity(0.2)),
                _buildStatRow(
                  'Total Decks',
                  '${_profileData?['totalDecks'] ?? 0}',
                ),
                Divider(color: Colors.white.withOpacity(0.2)),
                _buildStatRow(
                  'Joined',
                  _profileData?['createdAt']?.split('T')[0] ?? 'N/A',
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildAccuracyGauge() {
    final accuracy = (_statsData?['accuracy'] ?? 0).toDouble();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade900.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
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
                    Text(
                      'Accuracy',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${accuracy.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: _getAccuracyColor(accuracy),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: accuracy / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getAccuracyColor(accuracy),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '100%',
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
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildAttemptsChart() {
    final totalAttempts = _statsData?['totalAttempts'] ?? 0;
    final correctAnswers = _statsData?['correctAnswers'] ?? 0;
    final incorrectAnswers = totalAttempts - correctAnswers;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade900.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Performance',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: (totalAttempts * 1.2).toDouble(),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: correctAnswers.toDouble(),
                              color: const Color(0xFF4CAF50),
                              width: 40,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: totalAttempts.toDouble(),
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: incorrectAnswers.toDouble(),
                              color: const Color(0xFFF44336),
                              width: 40,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: totalAttempts.toDouble(),
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  value.toInt() == 0 ? 'Correct' : 'Incorrect',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            totalAttempts > 5
                                ? (totalAttempts / 5).toDouble()
                                : 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      const Color(0xFF4CAF50),
                      'Correct ($correctAnswers)',
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      const Color(0xFFF44336),
                      'Incorrect ($incorrectAnswers)',
                      Icons.error_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDecks() {
    final recentDecks = _statsData!['recentDecks'] as List<dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Decks',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: recentDecks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final deck = recentDecks[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade900.withOpacity(0.2),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getDeckColor(deck['category'] ?? ''),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      deck['name']?[0]?.toUpperCase() ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  deck['name'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  deck['category'] ?? 'N/A',
                  style: GoogleFonts.poppins(color: Colors.grey.shade400),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
              ),
            ).animate().fadeIn(delay: (700 + index * 100).ms);
          },
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
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
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.greenAccent;
    if (accuracy >= 60) return Colors.yellowAccent;
    if (accuracy >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getDeckColor(String category) {
    final colors = [
      const Color(0xFF8A2BE2),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFFE91E63),
    ];
    return colors[category.hashCode.abs() % colors.length];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
