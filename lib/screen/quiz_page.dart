import 'package:flutter/material.dart';
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

class _QuizPageState extends State<QuizPage> {
  final ApiService apiService = ApiService();
  late Future<Map<String, dynamic>> _quizFuture;
  List<dynamic> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  String? _selectedAnswer;
  bool _isAnswerSubmitted = false;
  Map<String, dynamic>? _progress;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _quizFuture = _startQuiz();
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
            backgroundColor: Colors.red,
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
          backgroundColor: result['isCorrect'] ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting answer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
      _isAnswerSubmitted = false;
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
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.deckTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _quizFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (_quizQuestions.isEmpty) {
            return const Center(child: Text('No quiz questions available'));
          }

          final currentQuestion = _quizQuestions[_currentQuestionIndex];
          final String? imageUrl = currentQuestion['imageUrl'] != null &&
                  currentQuestion['imageUrl'].isNotEmpty
              ? currentQuestion['imageUrl'].startsWith('/')
                  ? '${ApiService.baseUrl}${currentQuestion['imageUrl']}'
                  : '${ApiService.baseUrl}/${currentQuestion['imageUrl']}'
              : null;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress indicator
                LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _quizQuestions.length,
                  backgroundColor: Colors.grey.shade800,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.deckColor),
                ),
                const SizedBox(height: 20),
                // Question number
                Text(
                  'Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                // Question text
                Text(
                  currentQuestion['question'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Image if available
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.red),
                        );
                      },
                    ),
                  ),
                // Options
                Expanded(
                  child: ListView.builder(
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
                          buttonColor = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
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
                                    ? widget.deckColor.withOpacity(0.3)
                                    : Colors.grey.shade800),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(option),
                        ),
                      );
                    },
                  ),
                ),
                // Submit/Next button
                if (_isAnswerSubmitted && _currentQuestionIndex < _quizQuestions.length - 1)
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.deckColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Next Question'),
                  )
                else if (_isAnswerSubmitted && _currentQuestionIndex == _quizQuestions.length - 1)
                  ElevatedButton(
                    onPressed: _finishQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.deckColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Finish Quiz'),
                  )
                else
                  ElevatedButton(
                    onPressed: _selectedAnswer == null ? null : _submitAnswer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAnswer == null
                          ? Colors.grey
                          : widget.deckColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Submit Answer'),
                  ),
                // Progress info if available
                if (_progress != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Progress: ${_progress!['deckCompletionPercentage']}% complete',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Mastered: ${_progress!['mastered']}/${_progress!['totalFlashcards']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}