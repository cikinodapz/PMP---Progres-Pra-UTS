import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintText: 'Search Flashcards...',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Filter Dropdown (UI only)
            DropdownButton<String>(
              isExpanded: true,
              hint: const Text('Filter by Category', style: TextStyle(color: Colors.white70)),
              items: ['All', 'Math', 'Biology', 'History']
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: (value) {},
              dropdownColor: Colors.grey[800],
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Flashcard Sets List
            Expanded(
              child: ListView(
                children: [
                  FlashcardSetCard(
                    title: 'Math Basics',
                    category: 'Math',
                    progress: 0.75,
                    onTap: () {
                      Navigator.pushNamed(context, '/flashcard-set-detail');
                    },
                  ),
                  FlashcardSetCard(
                    title: 'Biology 101',
                    category: 'Biology',
                    progress: 0.4,
                    onTap: () {
                      Navigator.pushNamed(context, '/flashcard-set-detail');
                    },
                  ),
                  FlashcardSetCard(
                    title: 'World History',
                    category: 'History',
                    progress: 0.9,
                    onTap: () {
                      Navigator.pushNamed(context, '/flashcard-set-detail');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.cyanAccent.withOpacity(0.3),
        onPressed: () {
          Navigator.pushNamed(context, '/create-flashcard');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class FlashcardSetCard extends StatelessWidget {
  final String title;
  final String category;
  final double progress;
  final VoidCallback onTap;

  const FlashcardSetCard({
    super.key,
    required this.title,
    required this.category,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}