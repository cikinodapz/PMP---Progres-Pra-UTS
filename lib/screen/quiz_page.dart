import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:efeflascard/api/api_service.dart';

class QuizPage extends StatefulWidget {
  final String deckId;
  final String deckTitle;
  final Color deckColor;

  const QuizPage({
    super.key,
    required this.deckId,
    required this.deckTitle,
    required this.deckColor,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> _quizFuture;
  List<dynamic> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isAnswerSubmitted = false;
  Map<String, dynamic>? _progress;
  int _correctAnswers = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _quizFuture = _startQuiz();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  Future<Map<String, dynamic>> _startQuiz() async {
    try {
      final quizData = await apiService.startQuiz(widget.deckId);
      setState(() {
        _quizQuestions = quizData['quiz'];
      });
      return quizData;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start quiz: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return {};
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;

    try {
      final result = await apiService.submitAnswer(
        _quizQuestions[_currentQuestionIndex]['flashcardId'],
        _selectedAnswer!,
      );

      setState(() {
        _isAnswerSubmitted = true;
        _progress = result['progress'];
        if (result['isCorrect']) {
          _correctAnswers++;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['isCorrect'] ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting answer: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
      _isAnswerSubmitted = false;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _finishQuiz() {
    Navigator.pop(context, {
      'correctAnswers': _correctAnswers,
      'totalQuestions': _quizQuestions.length,
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
              widget.deckColor.withOpacity(0.2),
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
                            widget.deckColor.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          widget.deckTitle,
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
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _quizFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade700,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 18,
                            ),
                          ),
                        );
                      } else if (_quizQuestions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.quiz,
                                size: 60,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No quiz questions available',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final currentQuestion = _quizQuestions[_currentQuestionIndex];
                      final String? imageUrl = currentQuestion['imageUrl'] != null &&
                              currentQuestion['imageUrl'].isNotEmpty
                          ? currentQuestion['imageUrl'].startsWith('/')
                              ? '${ApiService.baseUrl}${currentQuestion['imageUrl']}'
                              : '${ApiService.baseUrl}/${currentQuestion['imageUrl']}'
                          : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: LinearProgressIndicator(
                              value: (_currentQuestionIndex + 1) / _quizQuestions.length,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(widget.deckColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Question number
                          Text(
                            'Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Question text
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.deckColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentQuestion['question'],
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.2),
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                if (imageUrl != null) ...[
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey.shade800,
                                        highlightColor: Colors.grey.shade700,
                                        child: Container(
                                          height: 150,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        height: 150,
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.error,
                                          color: Colors.redAccent,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Options
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentQuestion['options'].length,
                            itemBuilder: (context, index) {
                              final option = currentQuestion['options'][index];
                              final isCorrectAnswer =
                                  option == currentQuestion['correctAnswer'];
                              final isSelected = _selectedAnswer == option;

                              Color? buttonColor;
                              if (_isAnswerSubmitted) {
                                if (isCorrectAnswer) {
                                  buttonColor = Colors.green;
                                } else if (isSelected && !isCorrectAnswer) {
                                  buttonColor = Colors.redAccent;
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ElevatedButton(
                                  onPressed: _isAnswerSubmitted
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedAnswer = option;
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonColor ??
                                        (isSelected
                                            ? widget.deckColor.withOpacity(0.4)
                                            : Colors.grey.shade800),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: isSelected ? 4 : 1,
                                    shadowColor: widget.deckColor.withOpacity(0.3),
                                  ),
                                  child: Text(
                                    option,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Submit/Next button
                          if (_isAnswerSubmitted &&
                              _currentQuestionIndex < _quizQuestions.length - 1)
                            _buildActionButton(
                              text: 'Next Question',
                              onPressed: _nextQuestion,
                            )
                          else if (_isAnswerSubmitted &&
                              _currentQuestionIndex == _quizQuestions.length - 1)
                            _buildActionButton(
                              text: 'Finish Quiz',
                              onPressed: _finishQuiz,
                            )
                          else
                            _buildActionButton(
                              text: 'Submit Answer',
                              onPressed: _selectedAnswer == null ? null : _submitAnswer,
                              enabled: _selectedAnswer != null,
                            ),
                          // Progress info
                          if (_progress != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progress: ${_progress!['deckCompletionPercentage']}% complete',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Mastered: ${_progress!['mastered']}/${_progress!['totalFlashcards']}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return AnimatedScale(
      scale: enabled ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? widget.deckColor : Colors.grey.shade600,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: enabled ? 4 : 0,
          shadowColor: widget.deckColor.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}