import 'package:flutter/material.dart';
import 'package:voicenote/Models/FlashcardItem.dart';
import 'package:voicenote/Services/FlashcardService.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final FlashcardService _flashcardService = FlashcardService();

  bool _isLoading = true;
  String? _errorMessage;
  List<FlashcardItem> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    try {
      final flashcards = await _flashcardService.getFlashcards();

      if (!mounted) return;

      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load flashcards: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0D0F14);
    const teal = Color(0xFF00E5B0);
    const text = Color(0xFFF0F2FF);
    const subText = Color(0xFF8B92B8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: text),
        title: const Text(
          'Flashcards',
          style: TextStyle(color: text),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: teal),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              : _flashcards.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No flashcards yet.\nSubmit a quiz first to create them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: subText,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _flashcards.length,
                      itemBuilder: (context, index) {
                        final card = _flashcards[index];
                        return _FlashcardTile(card: card);
                      },
                    ),
    );
  }
}

class _FlashcardTile extends StatefulWidget {
  final FlashcardItem card;

  const _FlashcardTile({
    required this.card,
  });

  @override
  State<_FlashcardTile> createState() => _FlashcardTileState();
}

class _FlashcardTileState extends State<_FlashcardTile> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF141720);
    const border = Color(0xFF232840);
    const teal = Color(0xFF00E5B0);
    const purple = Color(0xFFA78BFA);
    const text = Color(0xFFF0F2FF);
    const subText = Color(0xFF8B92B8);

    return GestureDetector(
      onTap: () {
        setState(() {
          _showFront = !_showFront;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (_showFront ? teal : purple).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _showFront ? 'Question' : 'Answer',
                    style: TextStyle(
                      color: _showFront ? teal : purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.card.module,
                  style: const TextStyle(
                    color: subText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _showFront ? widget.card.question : widget.card.answer,
              style: const TextStyle(
                color: text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            if (!_showFront) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text(
                  'Correct Answer: ${widget.card.correctAnswer}',
                  style: const TextStyle(
                    color: subText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tap to flip',
                style: TextStyle(
                  color: subText,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}