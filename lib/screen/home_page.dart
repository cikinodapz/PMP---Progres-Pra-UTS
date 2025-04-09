import 'package:efeflascard/screen/create_flashcard_page.dart';
import 'package:efeflascard/screen/flashcard_set_detail_page.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> flashcardSets = [
    {
      'title': 'Math Basics',
      'category': 'Mathematics',
      'progress': 0.65,
      'totalCards': 20,
      'color': Colors.cyanAccent,
    },
    {
      'title': 'Biology 101',
      'category': 'Biology',
      'progress': 0.3,
      'totalCards': 15,
      'color': Colors.purpleAccent,
    },
    {
      'title': 'History Timeline',
      'category': 'History',
      'progress': 0.8,
      'totalCards': 25,
      'color': Colors.greenAccent,
    },
    {
      'title': 'Chemistry Elements',
      'category': 'Chemistry',
      'progress': 0.45,
      'totalCards': 30,
      'color': Colors.orangeAccent,
    },
    {
      'title': 'French Vocabulary',
      'category': 'Languages',
      'progress': 0.2,
      'totalCards': 50,
      'color': Colors.pinkAccent,
    },
  ];

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('FlashCard Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and Filter Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search flashcard sets...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.grey.shade400),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Cards
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStatCard(
                    'Total Sets', 
                    '5', 
                    Colors.cyanAccent.withOpacity(0.2),
                    Colors.cyanAccent
                  ),
                  _buildStatCard(
                    'In Progress', 
                    '3', 
                    Colors.purpleAccent.withOpacity(0.2),
                    Colors.purpleAccent
                  ),
                  _buildStatCard(
                    'Completed', 
                    '2', 
                    Colors.greenAccent.withOpacity(0.2),
                    Colors.greenAccent
                  ),
                  _buildStatCard(
                    'Mastered', 
                    '1', 
                    Colors.orangeAccent.withOpacity(0.2),
                    Colors.orangeAccent
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Flashcard Sets List
            Expanded(
              child: ListView.builder(
                itemCount: flashcardSets.length,
                itemBuilder: (context, index) {
                  final set = flashcardSets[index];
                  return _buildFlashcardSetCard(set, context);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateFlashcardPage()),
          );
        },
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor, Color borderColor) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardSetCard(Map<String, dynamic> set, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: set['color'].withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: set['color'].withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardSetDetailPage(
                title: set['title'],
                category: set['category'],
                color: set['color'],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    set['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: set['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: set['color'].withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      set['category'],
                      style: TextStyle(
                        color: set['color'],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${(set['progress'] * set['totalCards']).round()}/${set['totalCards']} cards studied',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: set['progress'],
                backgroundColor: Colors.grey.shade700,
                color: set['color'],
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                '${(set['progress'] * 100).round()}% complete',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}