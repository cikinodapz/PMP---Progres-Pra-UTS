import 'package:efeflascard/screen/study_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';

class FlashcardSetDetailPage extends StatefulWidget {
  final String title;
  final String category;
  final Color color;

  const FlashcardSetDetailPage({
    super.key,
    required this.title,
    required this.category,
    required this.color,
  });

  @override
  State<FlashcardSetDetailPage> createState() => _FlashcardSetDetailPageState();
}

class _FlashcardSetDetailPageState extends State<FlashcardSetDetailPage> {
  final List<Map<String, String>> flashcards = [
    {'question': 'What is the Pythagorean theorem?', 'answer': 'a² + b² = c²'},
    {'question': 'What is the derivative of x²?', 'answer': '2x'},
    {'question': 'What is the value of π (pi) to two decimal places?', 'answer': '3.14'},
    {'question': 'Solve for x: 2x + 5 = 15', 'answer': 'x = 5'},
    {'question': 'What is the area of a circle formula?', 'answer': 'πr²'},
  ];

  int _currentIndex = 0;
  bool _showAnswer = false;

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
            icon: const Icon(Icons.edit),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category and Study Mode Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.color.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.category,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudyModePage(
                          flashcards: flashcards,
                          title: widget.title,
                          color: widget.color,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.school, color: Colors.black),
                  label: Text(
                    'Study Mode',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Flashcard Count
            Text(
              '${flashcards.length} flashcards',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),

            // Flashcard List
            Expanded(
              child: ListView.builder(
                itemCount: flashcards.length,
                itemBuilder: (context, index) {
                  return _buildFlashcardItem(index);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new flashcard
        },
        backgroundColor: widget.color,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildFlashcardItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          flashcards[index]['question']!,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              flashcards[index]['answer']!,
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: widget.color),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}