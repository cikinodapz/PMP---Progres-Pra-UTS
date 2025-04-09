import 'package:flutter/material.dart';

class StudyModePage extends StatefulWidget {
  final List<Map<String, String>> flashcards;
  final String title;
  final Color color;

  const StudyModePage({
    super.key,
    required this.flashcards,
    required this.title,
    required this.color,
  });

  @override
  State<StudyModePage> createState() => _StudyModePageState();
}

class _StudyModePageState extends State<StudyModePage> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  int _correctAnswers = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.flashcards.length,
              backgroundColor: Colors.grey.shade800,
              color: widget.color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 20),
            Text(
              '${_currentIndex + 1}/${widget.flashcards.length}',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Score: $_correctAnswers/${widget.flashcards.length}',
              style: TextStyle(
                color: widget.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Flashcard
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey<bool>(_showAnswer),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.color.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.color.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          _showAnswer 
                            ? widget.flashcards[_currentIndex]['answer']!
                            : widget.flashcards[_currentIndex]['question']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Answer Controls
            if (_showAnswer) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Wrong answer
                      _nextCard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 16
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.redAccent,
                          width: 2),
                      ),
                    ),
                    child: const Text('I was wrong'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Correct answer
                      setState(() {
                        _correctAnswers++;
                      });
                      _nextCard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24, 
                        vertical: 16
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.greenAccent,
                          width: 2),
                      ),
                    ),
                    child: const Text('I knew it!'),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAnswer = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40, 
                    vertical: 16
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: widget.color,
                      width: 2),
                  ),
                ),
                child: const Text('Show Answer'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _nextCard() {
    setState(() {
      _showAnswer = false;
      if (_currentIndex < widget.flashcards.length - 1) {
        _currentIndex++;
      } else {
        // Show completion dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey.shade800,
            title: Text(
              'Study Complete!',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'You scored $_correctAnswers out of ${widget.flashcards.length}',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'Finish',
                  style: TextStyle(color: widget.color),
                ),
              ),
            ],
          ),
        );
      }
    });
  }
}