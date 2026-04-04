import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feedback_service.dart';

// FeedbackSheet
// A modal bottom sheet with a feedback text field,
// send button with cooldown, and character counter.

const _maxCharacters = 2000;
const _cooldownDuration = 60;
const _cooldownKey = 'feedpush_last_send_timestamp';

class FeedbackSheet extends StatefulWidget {
  final String feedbackPlaceholder;
  final String sendButtonText;
  final String successMessage;
  final String errorMessage;

  const FeedbackSheet({
    super.key,
    this.feedbackPlaceholder = "What's on your mind?",
    this.sendButtonText = 'Send',
    this.successMessage = 'Thank you for your feedback!',
    this.errorMessage =
        'Could not send feedback. Please check your connection and try again.',
  });

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _feedbackController = TextEditingController();
  final _feedbackFocus = FocusNode();

  bool _isSending = false;
  bool _showSuccess = false;
  bool _showError = false;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  bool get _isSendDisabled =>
      _feedbackController.text.trim().isEmpty ||
      _feedbackController.text.length > _maxCharacters ||
      _isSending ||
      _cooldownRemaining > 0;

  @override
  void initState() {
    super.initState();
    _feedbackController.addListener(() => setState(() {}));
    _checkExistingCooldown();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _feedbackFocus.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSend = prefs.getInt(_cooldownKey) ?? 0;
    if (lastSend > 0) {
      final elapsed =
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - lastSend;
      final remaining = _cooldownDuration - elapsed;
      if (remaining > 0) {
        setState(() => _cooldownRemaining = remaining);
        _startCooldownTimer();
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cooldownRemaining > 0) {
        setState(() => _cooldownRemaining -= 1);
      } else {
        _cooldownTimer?.cancel();
      }
    });
  }

  Future<void> _saveCooldownTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _cooldownKey,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> _sendFeedback() async {
    _feedbackFocus.unfocus();
    setState(() {
      _isSending = true;
      _showError = false;
    });

    final result = await FeedbackService.send(
      text: _feedbackController.text,
    );

    if (!mounted) return;

    if (result.success) {
      HapticFeedback.mediumImpact();
      setState(() => _showSuccess = true);
      await _saveCooldownTimestamp();
      setState(() => _cooldownRemaining = _cooldownDuration);
      _startCooldownTimer();
      _feedbackController.clear();

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _showError = true);
    }

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Feedback',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Feedback text field
                TextField(
                  controller: _feedbackController,
                  focusNode: _feedbackFocus,
                  maxLines: 5,
                  maxLength: _maxCharacters,
                  decoration: InputDecoration(
                    hintText: widget.feedbackPlaceholder,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText:
                        '${_feedbackController.text.length} / $_maxCharacters',
                  ),
                ),
                const SizedBox(height: 24),

                // Send button
                FilledButton(
                  onPressed: _isSendDisabled ? null : _sendFeedback,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : _cooldownRemaining > 0
                          ? Text(
                              '${widget.sendButtonText} (${_cooldownRemaining}s)',
                            )
                          : Text(widget.sendButtonText),
                ),

                // Error message
                if (_showError) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.errorMessage,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),

            // Success overlay
            if (_showSuccess)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.successMessage,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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
}
