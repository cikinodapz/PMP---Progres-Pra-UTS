import 'dart:io';
import 'dart:math';
import 'package:efeflascard/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:efeflascard/screen/quiz_page.dart';

class FlashcardSetDetailPage extends StatefulWidget {
  final String deckId;
  final String title;
  final String category;
  final Color color;

  const FlashcardSetDetailPage({
    super.key,
    required this.deckId,
    required this.title,
    required this.category,
    required this.color,
  });

  @override
  State<FlashcardSetDetailPage> createState() => _FlashcardSetDetailPageState();
}

class _FlashcardSetDetailPageState extends State<FlashcardSetDetailPage> with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _flashcardsFuture;
  final ApiService apiService = ApiService();
  final Map<int, bool> _isFlipped = {};
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _flashcardsFuture = _fetchFlashcards();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFlashcards() async {
    try {
      final flashcardsData = await apiService.getFlashcards(widget.deckId);
      return List<Map<String, dynamic>>.from(flashcardsData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load flashcards: $e'), backgroundColor: Colors.red),
        );
      }
      return [];
    }
  }

  void _showAddFlashcardDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    File? selectedImage;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.grey.shade900,
              title: Text('Add New Flashcard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Question',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedImage = File(pickedFile.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image, color: Colors.black),
                      label: const Text('Pick Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selectedImage!, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade400)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final question = questionController.text.trim();
                      final answer = answerController.text.trim();
                      if (question.isEmpty || answer.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Question and Answer are required!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Creating flashcard...'), duration: Duration(seconds: 1)),
                      );
                      await apiService.addFlashcard(widget.deckId, question, answer, selectedImage);
                      Navigator.pop(context);
                      setState(() {
                        _flashcardsFuture = _fetchFlashcards();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flashcard created successfully!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save', style: GoogleFonts.poppins(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditFlashcardDialog(Map<String, dynamic> flashcard) {
    final questionController = TextEditingController(text: flashcard['question']);
    final answerController = TextEditingController(text: flashcard['answer']);
    File? selectedImage;
    String? currentImageUrl = flashcard['imageUrl'];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.grey.shade900,
              title: Text('Edit Flashcard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Question',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: answerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        labelStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade700),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            selectedImage = File(pickedFile.path);
                            currentImageUrl = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.image, color: Colors.black),
                      label: const Text('Pick New Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color.withOpacity(0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                    if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: currentImageUrl!.startsWith('/')
                                ? '${ApiService.baseUrl}$currentImageUrl'
                                : '${ApiService.baseUrl}/$currentImageUrl',
                            height: 100,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(selectedImage!, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade400)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final question = questionController.text.trim();
                      final answer = answerController.text.trim();
                      if (question.isEmpty || answer.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Question and Answer are required!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Updating flashcard...'), duration: Duration(seconds: 1)),
                      );
                      await apiService.editFlashcard(flashcard['id'], question, answer, selectedImage);
                      Navigator.pop(context);
                      setState(() {
                        _flashcardsFuture = _fetchFlashcards();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flashcard updated successfully!'), backgroundColor: Colors.green),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save', style: GoogleFonts.poppins(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.grey.shade900,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.edit, color: Colors.white70),
            //     onPressed: () {},
            //   ),
            //   IconButton(
            //     icon: const Icon(Icons.delete, color: Colors.white70),
            //     onPressed: () {},
            //   ),
            // ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: widget.color.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.category,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizPage(
                              deckId: widget.deckId,
                              deckTitle: widget.title,
                              deckColor: widget.color,
                            ),
                          ),
                        ).then((result) {
                          if (result != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Quiz completed! ${result['correctAnswers']}/${result['totalQuestions']} correct answers',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 4,
                      ),
                      child: Text(
                        'Start Quiz',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _flashcardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: Colors.grey.shade700,
                      highlightColor: Colors.grey.shade600,
                      child: Container(
                        height: 20,
                        width: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error loading flashcards',
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
                    );
                  }
                  final flashcards = snapshot.data ?? [];
                  return Text(
                    '${flashcards.length} flashcards',
                    style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 16),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: FutureBuilder<List<Map<String, dynamic>>>(
              future: _flashcardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Shimmer.fromColors(
                        baseColor: Colors.grey.shade700,
                        highlightColor: Colors.grey.shade600,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      childCount: 3,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No flashcards available',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  );
                }

                final flashcards = snapshot.data!;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: AnimationController(
                          vsync: this,
                          duration: Duration(milliseconds: 500 + index * 100),
                          value: 1,
                        )..forward(),
                        curve: Curves.easeIn,
                      ),
                      child: _buildFlashcardItem(flashcards[index], index),
                    ),
                    childCount: flashcards.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _fabController, curve: Curves.easeInOut)),
        child: FloatingActionButton(
          onPressed: () {
            _fabController.forward().then((_) => _fabController.reverse());
            _showAddFlashcardDialog();
          },
          backgroundColor: widget.color,
          elevation: 6,
          child: const Icon(Icons.add, color: Colors.black, size: 30),
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(Map<String, dynamic> flashcard, int index) {
    String? imageUrl;
    if (flashcard['imageUrl'] != null && flashcard['imageUrl'].isNotEmpty) {
      imageUrl = flashcard['imageUrl'].startsWith('/')
          ? '${ApiService.baseUrl}${flashcard['imageUrl']}'
          : '${ApiService.baseUrl}/${flashcard['imageUrl']}';
    }

    final isFlipped = _isFlipped[index] ?? false;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isFlipped[index] = !isFlipped;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isFlipped ? widget.color.withOpacity(0.3) : Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(isFlipped ? pi : 0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.5), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isFlipped
                  ? _buildBackSide(flashcard, imageUrl)
                  : _buildFrontSide(flashcard),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide(Map<String, dynamic> flashcard) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AutoSizeText(
                flashcard['question'] ?? 'No question',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                minFontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: widget.color, size: 24),
                onPressed: () => _showEditFlashcardDialog(flashcard),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 24),
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      backgroundColor: Colors.grey.shade900,
                      title: Text('Delete Flashcard', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                      content: Text('Are you sure you want to delete this flashcard?', style: GoogleFonts.poppins(color: Colors.grey.shade300)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade400)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (shouldDelete != true) return;

                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deleting flashcard...'), duration: Duration(seconds: 1)),
                    );
                    await apiService.deleteFlashcard(flashcard['id']);
                    setState(() {
                      _flashcardsFuture = _fetchFlashcards();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Flashcard deleted successfully!'), backgroundColor: Colors.green),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(Map<String, dynamic> flashcard, String? imageUrl) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AutoSizeText(
                flashcard['answer'] ?? 'No answer',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade300,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                minFontSize: 12,
                overflow: TextOverflow.ellipsis,
              ),
              if (imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade700,
                      highlightColor: Colors.grey.shade600,
                      child: Container(
                        height: 100,
                        color: Colors.grey,
                      ),
                    ),
                    errorWidget: (context, url, error) => const Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }
}