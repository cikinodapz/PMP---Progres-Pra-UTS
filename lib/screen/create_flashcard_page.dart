import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:efeflascard/api/api_service.dart';

class CreateFlashcardPage extends StatefulWidget {
  const CreateFlashcardPage({super.key});

  @override
  State<CreateFlashcardPage> createState() => _CreateFlashcardPageState();
}

class _CreateFlashcardPageState extends State<CreateFlashcardPage> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isLoading = false;
  String? _nameError;
  String? _categoryError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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

  Future<void> _createDeck() async {
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'Deck name is required' : null;
      _categoryError = _categoryController.text.isEmpty ? 'Category is required' : null;
    });

    if (_nameError != null || _categoryError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all fields',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.createDeck(
        _nameController.text,
        _categoryController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'], style: GoogleFonts.poppins()),
            backgroundColor: Color(0xFF7F00FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create deck: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
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
              const Color(0xFF8A2BE2).withOpacity(0.2),
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
                            const Color(0xFF8A2BE2).withOpacity(0.7),
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
                          'Create New Deck',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Deck Details',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up your new flashcard deck',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Deck Name',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A2BE2).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade800.withOpacity(0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF8A2BE2),
                                width: 2,
                              ),
                            ),
                            errorText: _nameError,
                            errorStyle: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            hintText: 'Enter deck name',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.title_rounded, color: Colors.grey.shade400),
                          ),
                          onChanged: (value) => setState(() {
                            _nameError = value.isEmpty ? 'Deck name is required' : null;
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Category',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade300,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8A2BE2).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _categoryController,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade800.withOpacity(0.7),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF8A2BE2),
                                width: 2,
                              ),
                            ),
                            errorText: _categoryError,
                            errorStyle: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            hintText: 'Enter category',
                            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.category_rounded, color: Colors.grey.shade400),
                          ),
                          onChanged: (value) => setState(() {
                            _categoryError = value.isEmpty ? 'Category is required' : null;
                          }),
                        ),
                      ),
                      const SizedBox(height: 40),
                      AnimatedScale(
                        scale: _isLoading ? 0.95 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createDeck,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              shadowColor: const Color(0xFF8A2BE2).withOpacity(0.5),
                              surfaceTintColor: Colors.transparent,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8A2BE2), Color(0xFF7241D1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_rounded),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Create Deck',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}