import 'package:flutter/material.dart';

import 'feedback_sheet.dart';

// FeedbackButton
// A card-style button that opens the feedback sheet when tapped.
// Configurable text and icon -- pass your own strings to localize or customize.

class FeedbackButton extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  // Pass-through to FeedbackSheet
  final String feedbackPlaceholder;
  final String sendButtonText;
  final String successMessage;
  final String errorMessage;

  const FeedbackButton({
    super.key,
    this.icon = '\u{1F4A1}',
    this.title = 'Have suggestions?',
    this.subtitle = 'Share your ideas with us',
    this.feedbackPlaceholder = "What's on your mind?",
    this.sendButtonText = 'Send',
    this.successMessage = 'Thank you for your feedback!',
    this.errorMessage =
        'Could not send feedback. Please check your connection and try again.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showFeedbackSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FeedbackSheet(
        feedbackPlaceholder: feedbackPlaceholder,
        sendButtonText: sendButtonText,
        successMessage: successMessage,
        errorMessage: errorMessage,
      ),
    );
  }
}
