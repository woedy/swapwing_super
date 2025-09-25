import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swapwing/models/app_feedback.dart';
import 'package:swapwing/services/feedback_service.dart';
import 'package:swapwing/services/analytics_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  FeedbackCategory? _selectedCategory;
  double _sentimentScore = 4;
  bool _allowContact = false;
  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;

  List<FeedbackCategory> _categories = const <FeedbackCategory>[];
  List<FeedbackSubmission> _recentSubmissions = const <FeedbackSubmission>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await FeedbackService.fetchCategories();
      final submissions = await FeedbackService.fetchRecentSubmissions();
      setState(() {
        _categories = categories;
        _recentSubmissions = submissions;
        _selectedCategory = categories.isNotEmpty ? categories.first : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'We had trouble loading the feedback module. Pull to refresh and try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a topic so we can route your note.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    if (!_allowContact) {
      _contactController.clear();
    }

    try {
      final sentiment = FeedbackSentiment(
        score: _sentimentScore.round().clamp(1, 5),
        label: _sentimentLabel(_sentimentScore),
      );

      final submission = await FeedbackService.submitFeedback(
        category: _selectedCategory!,
        message: _messageController.text,
        sentiment: sentiment,
        allowContact: _allowContact,
        contact: _contactController.text,
      );

      if (!mounted) return;

      AnalyticsService.instance.logEvent('feedback_form_submitted', properties: {
        'category': _selectedCategory!.id,
        'sentiment': sentiment.score,
        'allow_contact': _allowContact,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! We received your feedback.')),
      );

      setState(() {
        _recentSubmissions = [submission, ..._recentSubmissions];
        _messageController.clear();
        _allowContact = false;
        _sentimentScore = 4;
        if (!_allowContact) {
          _contactController.clear();
        }
      });
    } on FeedbackServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Support'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const _LoadingView()
            : _errorMessage != null
                ? _ErrorView(
                    message: _errorMessage!,
                    onRetry: _loadData,
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tell us how SwapWing can get better',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our team reads every note. Pick a topic and share what\'s on your mind.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Topic',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _categories
                              .map(
                                (category) => _CategoryChoice(
                                  category: category,
                                  selected: _selectedCategory?.id == category.id,
                                  onSelected: () {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                    _messageController.text = '';
                                  },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'How was your experience?',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _SentimentSlider(
                          score: _sentimentScore,
                          onChanged: (value) => setState(() {
                            _sentimentScore = value;
                          }),
                          label: _sentimentLabel(_sentimentScore),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _messageController,
                          maxLines: 6,
                          minLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Share details',
                            hintText: _selectedCategory?.placeholder ??
                                'What happened? The more context the better.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          title: const Text('Allow SwapWing to reach out'),
                          subtitle: const Text(
                            'We\'ll follow up over email only if we need more info.',
                          ),
                          value: _allowContact,
                          onChanged: (value) => setState(() {
                            _allowContact = value;
                            if (!value) {
                              _contactController.clear();
                            }
                          }),
                        ),
                        if (_allowContact) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _contactController,
                            decoration: InputDecoration(
                              labelText: 'Preferred contact (optional)',
                              hintText: 'Email or phone number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(_isSubmitting ? 'Sending...' : 'Submit feedback'),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_recentSubmissions.isNotEmpty) ...[
                          Text(
                            'Recent submissions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ..._recentSubmissions
                              .take(5)
                              .map(
                                (submission) => Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _categoryTitle(submission.categoryId),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          submission.message,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                        if (submission.contact != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Preferred contact: ${submission.contact}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('MMM d, yyyy · h:mm a')
                                                  .format(submission.createdAt),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                            ),
                                            if (submission.sentiment != null)
                                              Chip(
                                                label: Text(
                                                  '${submission.sentiment!.label} · ${submission.sentiment!.score}/5',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ] else
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.inbox_outlined, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Your future feedback will appear here.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Theme.of(context).hintColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _sentimentLabel(double score) {
    if (score >= 4.5) return 'Delighted';
    if (score >= 3.5) return 'Happy';
    if (score >= 2.5) return 'Okay';
    if (score >= 1.5) return 'Frustrated';
    return 'Blocked';
  }

  String _categoryTitle(String categoryId) {
    return _categories.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => FeedbackCategory(
        id: categoryId,
        title: categoryId,
        description: '',
        placeholder: '',
      ),
    ).title;
  }
}

class _SentimentSlider extends StatelessWidget {
  final double score;
  final ValueChanged<double> onChanged;
  final String label;

  const _SentimentSlider({
    required this.score,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text('${score.toStringAsFixed(1)} / 5'),
          ],
        ),
        Slider(
          value: score,
          min: 1,
          max: 5,
          divisions: 8,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  final FeedbackCategory category;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.of(context).size.width - 32; // padding in view
    final chipWidth = (availableWidth / 2) - 12; // account for wrap spacing
    final width = chipWidth.clamp(160.0, 260.0);

    return SizedBox(
      width: width,
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onSelected(),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        selectedColor:
            Theme.of(context).colorScheme.primary.withOpacity(0.12),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              category.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 120),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 12),
        Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
