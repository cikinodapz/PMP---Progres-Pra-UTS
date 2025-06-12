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

class _FlashcardSetDetailPageState extends State<FlashcardSetDetailPage>
    with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _flashcardsFuture;
  final ApiService apiService = ApiService();
  final Map<int, bool> _isFlipped = {};
  final Map<int, AnimationController> _cardControllers = {};

  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _flashcardsFuture = _fetchFlashcards();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOutCubic),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFlashcards() async {
    try {
      final flashcardsData = await apiService.getFlashcards(widget.deckId);
      return List<Map<String, dynamic>>.from(flashcardsData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully'),
            backgroundColor: widget.color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.grey.shade900.withOpacity(0.95),
              title: Text(
                'Add New Flashcard',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Question',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answerController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      icon: const Icon(Icons.image, size: 20),
                      label: Text(
                        'Pick Image',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        elevation: 2,
                      ),
                    ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 120,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final question = questionController.text.trim();
                      final answer = answerController.text.trim();
                      if (question.isEmpty || answer.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Question and Answer are required!'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Creating flashcard...'),
                          backgroundColor: widget.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                      await apiService.addFlashcard(
                        widget.deckId,
                        question,
                        answer,
                        selectedImage,
                      );
                      Navigator.pop(context);
                      setState(() {
                        _flashcardsFuture = _fetchFlashcards();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Flashcard created successfully!'),
                          backgroundColor: widget.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 2,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditFlashcardDialog(Map<String, dynamic> flashcard) {
    final questionController = TextEditingController(
      text: flashcard['question'],
    );
    final answerController = TextEditingController(text: flashcard['answer']);
    File? selectedImage;
    String? currentImageUrl = flashcard['imageUrl'];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: Colors.grey.shade900.withOpacity(0.95),
              title: Text(
                'Edit Flashcard',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Question',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: answerController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Answer',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade800,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      icon: const Icon(Icons.image, size: 20),
                      label: Text(
                        'Pick New Image',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color.withOpacity(0.9),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        elevation: 2,
                      ),
                    ),
                    if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl:
                                currentImageUrl!.startsWith('/')
                                    ? '${ApiService.baseUrl}$currentImageUrl'
                                    : '${ApiService.baseUrl}/$currentImageUrl',
                            height: 120,
                            width: 200,
                            fit: BoxFit.cover,
                            errorWidget:
                                (context, url, error) => Container(
                                  height: 120,
                                  width: 200,
                                  color: Colors.grey.shade800,
                                  child: const Icon(
                                    Icons.error,
                                    color: Colors.redAccent,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            selectedImage!,
                            height: 120,
                            width: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final question = questionController.text.trim();
                      final answer = answerController.text.trim();
                      if (question.isEmpty || answer.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Question and Answer are required!'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Updating flashcard...'),
                          backgroundColor: widget.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      await apiService.editFlashcard(
                        flashcard['id'],
                        question,
                        answer,
                        selectedImage,
                      );
                      Navigator.pop(context);
                      setState(() {
                        _flashcardsFuture = _fetchFlashcards();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Flashcard updated successfully!'),
                          backgroundColor: widget.color,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    elevation: 2,
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFlashcardOptionsDialog(String flashcardId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.grey.shade900.withOpacity(0.95),
          title: Text(
            'Flashcard Options',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Choose an action for this flashcard:',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade300,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeckSelectionDialog(flashcardId, isCopy: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'Copy',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeckSelectionDialog(flashcardId, isCopy: false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                'Cut',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeckSelectionDialog(
    String flashcardId, {
    required bool isCopy,
  }) async {
    try {
      final decks = await apiService.getAllDecks();
      // Filter out current deck
      final filteredDecks =
          decks.where((deck) => deck['id'] != widget.deckId).toList();

      if (filteredDecks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No other decks available to ${isCopy ? 'copy' : 'move'} to',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      String? selectedDeckId;

      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.6),
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: Colors.grey.shade900.withOpacity(0.95),
                title: Text(
                  'Select Destination Deck',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredDecks.length,
                    itemBuilder: (context, index) {
                      final deck = filteredDecks[index];
                      return ListTile(
                        title: Text(
                          deck['name'],
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        subtitle: Text(
                          deck['category'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                          ),
                        ),
                        leading: Radio<String>(
                          value: deck['id'],
                          groupValue: selectedDeckId,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDeckId = value;
                            });
                          },
                          fillColor: MaterialStateProperty.all(widget.color),
                        ),
                        onTap: () {
                          setDialogState(() {
                            selectedDeckId = deck['id'];
                          });
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedDeckId == null
                            ? null
                            : () async {
                              Navigator.pop(context); // Close the dialog

                              try {
                                // Show processing SnackBar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${isCopy ? 'Copying' : 'Moving'} flashcard...',
                                    ),
                                    backgroundColor: widget.color,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );

                                if (isCopy) {
                                  await apiService.copyFlashcards(
                                    selectedDeckId!,
                                    [flashcardId],
                                  );
                                } else {
                                  await apiService.moveFlashcards(
                                    selectedDeckId!,
                                    [flashcardId],
                                  );

                                  // Refresh flashcard list after move
                                  // Pastikan ini dipanggil dalam context widget yang benar
                                  if (mounted) {
                                    setState(() {
                                      _flashcardsFuture = _fetchFlashcards();
                                    });
                                  }
                                }

                                // Show success SnackBar
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Flashcard ${isCopy ? 'copied' : 'moved'} successfully!',
                                      ),
                                      backgroundColor: widget.color,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Successfully'),
                                      backgroundColor: widget.color,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      isCopy ? 'Copy' : 'Move',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading decks: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
              widget.color.withOpacity(0.2),
              Colors.grey.shade900,
              Colors.black87,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
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
                            widget.color.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
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
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.color.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                widget.category,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => QuizPage(
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
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      });
                    },
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: Text(
                      'Start Quiz',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _flashcardsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Shimmer.fromColors(
                        baseColor: Colors.grey.shade800,
                        highlightColor: Colors.grey.shade700,
                        child: Container(
                          height: 24,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error loading flashcards',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 16,
                        ),
                      );
                    }
                    final flashcards = snapshot.data ?? [];
                    return Text(
                      '${flashcards.length} Flashcards',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade700,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(20),
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
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.note_add,
                              size: 60,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No flashcards yet\nTap the + button to add one!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 18,
                                height: 1.5,
                              ),
                            ),
                          ],
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
                            duration: Duration(milliseconds: 600 + index * 100),
                            value: 1,
                          )..forward(),
                          curve: Curves.easeOutCubic,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: AnimationController(
                                vsync: this,
                                duration: Duration(
                                  milliseconds: 600 + index * 100,
                                ),
                                value: 1,
                              )..forward(),
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: _buildFlashcardItem(flashcards[index], index),
                        ),
                      ),
                      childCount: flashcards.length,
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: MouseRegion(
        onEnter: (_) => _fabController.forward(),
        onExit: (_) => _fabController.reverse(),
        child: ScaleTransition(
          scale: _fabScaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widget.color, widget.color.withOpacity(0.7)],
                stops: const [0.0, 1.0],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 3,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () async {
                  // Play a slight rotation animation on tap
                  await _fabController.forward();
                  _showAddFlashcardDialog();
                  await Future.delayed(const Duration(milliseconds: 100));
                  _fabController.reverse();
                },
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: widget.color.withOpacity(0.2),
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns:
                        _fabController.value *
                        0.125, // Subtle 45-degree rotation
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.add,
                      size: 36,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcardItem(Map<String, dynamic> flashcard, int index) {
    _cardControllers.putIfAbsent(index, () {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
      if (_isFlipped[index] ?? false) {
        controller.value = 1.0;
      }
      return controller;
    });

    String? imageUrl;
    if (flashcard['imageUrl'] != null && flashcard['imageUrl'].isNotEmpty) {
      imageUrl =
          flashcard['imageUrl'].startsWith('/')
              ? '${ApiService.baseUrl}${flashcard['imageUrl']}'
              : '${ApiService.baseUrl}/${flashcard['imageUrl']}';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isFlipped[index] = !(_isFlipped[index] ?? false);
          if (_isFlipped[index]!) {
            _cardControllers[index]!.forward();
          } else {
            _cardControllers[index]!.reverse();
          }
        });
      },
      onLongPress: () {
        _showFlashcardOptionsDialog(flashcard['id']);
      },
      child: AnimatedBuilder(
        animation: _cardControllers[index]!,
        builder: (context, child) {
          final animation = _cardControllers[index]!;
          final angle = animation.value * pi;

          final transform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.0015)
                ..rotateY(angle);

          final scale = 1.0 - (0.08 * sin(angle));
          transform.scale(scale, scale);

          final glowOpacity = 0.3 + (0.2 * cos(angle * 2)).abs();

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade800, Colors.grey.shade900],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(glowOpacity),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: widget.color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child:
                    angle < pi / 2
                        ? _buildFrontSide(flashcard)
                        : Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _buildBackSide(flashcard, imageUrl),
                        ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide(Map<String, dynamic> flashcard) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.color.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: AutoSizeText(
                    flashcard['question'] ?? 'No question',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    minFontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    color: widget.color,
                    onPressed: () => _showEditFlashcardDialog(flashcard),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.delete,
                    color: Colors.redAccent,
                    onPressed: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              backgroundColor: Colors.grey.shade900.withOpacity(
                                0.95,
                              ),
                              title: Text(
                                'Delete Flashcard',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete this flashcard?',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade300,
                                  fontSize: 16,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (shouldDelete != true) return;

                      try {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleting flashcard...'),
                            backgroundColor: widget.color,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                        await apiService.deleteFlashcard(flashcard['id']);
                        setState(() {
                          _flashcardsFuture = _fetchFlashcards();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Flashcard deleted successfully!'),
                            backgroundColor: widget.color,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackSide(Map<String, dynamic> flashcard, String? imageUrl) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [widget.color.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutoSizeText(
                  flashcard['answer'] ?? 'No answer',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade200,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 642,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
                if (imageUrl != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey.shade800,
                            highlightColor: Colors.grey.shade700,
                            child: Container(height: 120, color: Colors.grey),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 120,
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
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    for (final controller in _cardControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
