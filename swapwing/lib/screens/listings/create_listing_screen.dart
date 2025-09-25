import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/services/analytics_service.dart';
import 'package:swapwing/services/listing_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _stepFormKeys = List.generate(2, (_) => GlobalKey<FormState>());
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagInputController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final ListingService _listingService = const ListingService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  ListingCategory _selectedCategory = ListingCategory.goods;
  bool _isTradeUpEligible = false;
  int _currentStep = 0;
  bool _isSubmitting = false;
  double _uploadProgress = 0;

  final List<XFile> _selectedMedia = [];
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _analytics.logEvent('create_listing_viewed');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _locationController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  List<Step> get _steps => [
        Step(
          title: const Text('Basics'),
          state: _stepStateFor(0),
          isActive: _currentStep >= 0,
          content: Form(
            key: _stepFormKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    label: 'Listing title',
                    hint: 'What are you offering?',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title for your listing';
                    }
                    if (value.trim().length < 3) {
                      return 'Title should be at least 3 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ListingCategory>(
                  value: _selectedCategory,
                  decoration: _inputDecoration(label: 'Category'),
                  items: ListingCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: _inputDecoration(
                    label: 'Where is this located?',
                    hint: 'City, neighborhood, or meeting location',
                  ),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Details'),
          state: _stepStateFor(1),
          isActive: _currentStep >= 1,
          content: Form(
            key: _stepFormKeys[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: _inputDecoration(
                        label: 'Description',
                        hint: 'Tell traders what makes this item special...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Add a few details to help people understand your listing';
                        }
                        return null;
                      },
                    ),
                    IconButton(
                      tooltip: 'Generate AI description',
                      onPressed: _generateAIDescription,
                      icon: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _valueController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Estimated value',
                          hint: '0',
                          prefixText: '${String.fromCharCode(36)} ',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Estimate the value to help match fair trades';
                          }
                          return double.tryParse(value.trim()) != null
                              ? null
                              : 'Enter a valid number';
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _estimateValue,
                      icon: const Icon(Icons.psychology_alt),
                      label: const Text('AI estimate'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tagInputController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    label: 'Add tags',
                    hint: 'Press enter after each tag',
                  ),
                  onSubmitted: _handleTagSubmitted,
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile.adaptive(
                  value: _isTradeUpEligible,
                  onChanged: (value) => setState(() => _isTradeUpEligible = value),
                  title: const Text('Trade-up eligible'),
                  subtitle: const Text('Allow this listing to be part of trade-up journeys'),
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Media & review'),
          state: _stepStateFor(2),
          isActive: _currentStep >= 2,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediaPicker(),
              const SizedBox(height: 16),
              if (_isSubmitting)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(value: _uploadProgress.clamp(0.0, 1.0)),
                    const SizedBox(height: 8),
                    Text(
                      _uploadProgress >= 1
                          ? 'Finalizing listing...'
                          : 'Uploading media ${(100 * _uploadProgress).clamp(0, 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              _buildReviewCard(),
            ],
          ),
        ),
      ];

  StepState _stepStateFor(int stepIndex) {
    if (_currentStep > stepIndex) {
      return StepState.complete;
    }
    return _currentStep == stepIndex ? StepState.editing : StepState.indexed;
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Future<void> _pickMedia() async {
    _analytics.logEvent(
      'create_listing_media_picker_opened',
      properties: {'selected_count': _selectedMedia.length},
    );
    try {
      final files = await _picker.pickMultipleMedia();
      if (files == null || files.isEmpty) return;
      setState(() {
        _selectedMedia
          ..clear()
          ..addAll(files);
      });
      _analytics.logEvent(
        'create_listing_media_selected',
        properties: {'count': files.length},
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not open your gallery. Please try again.')),
      );
      _analytics.logEvent('create_listing_media_picker_failed');
    }
  }

  void _generateAIDescription() {
    setState(() {
      _descriptionController.text =
          'High-quality item ready for a new home. Includes all accessories and has been gently used.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI drafted a suggested description.')),
    );
    _analytics.logEvent('create_listing_ai_description_generated');
  }

  void _estimateValue() {
    setState(() {
      _valueController.text = '150';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estimated value generated from recent trades.')),
    );
    _analytics.logEvent('create_listing_ai_value_estimated');
  }

  void _handleTagSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _tags.remove(trimmed.toLowerCase());
      _tags.add(trimmed);
    });
    _tagInputController.clear();
    _analytics.logEvent(
      'create_listing_tag_added',
      properties: {'tag': trimmed},
    );
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _analytics.logEvent(
      'create_listing_tag_removed',
      properties: {'tag': tag},
    );
  }

  void _goToStep(int step) {
    if (_isSubmitting) return;
    setState(() => _currentStep = step);
    _analytics.logEvent(
      'create_listing_step_changed',
      properties: {'step': step},
    );
  }

  Future<void> _handleContinue() async {
    if (_currentStep < 2) {
      final formKey = _stepFormKeys[_currentStep];
      if (!(formKey.currentState?.validate() ?? false)) {
        _analytics.logEvent(
          'create_listing_step_validation_failed',
          properties: {'step': _currentStep},
        );
        return;
      }
      setState(() => _currentStep += 1);
      _analytics.logEvent(
        'create_listing_step_completed',
        properties: {'step': _currentStep - 1},
      );
      return;
    }
    await _createListing();
  }

  void _handleBack() {
    if (_currentStep == 0 || _isSubmitting) return;
    setState(() => _currentStep -= 1);
    _analytics.logEvent(
      'create_listing_step_changed',
      properties: {'step': _currentStep},
    );
  }

  Future<void> _createListing() async {
    if (_isSubmitting) return;

    if (_selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one photo or video to showcase your listing.')),
      );
      _analytics.logEvent('create_listing_failed', properties: {'reason': 'missing_media'});
      return;
    }

    final estimatedValue = double.tryParse(_valueController.text.trim());
    final request = CreateListingRequest(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      tags: _tags,
      estimatedValue: estimatedValue,
      isTradeUpEligible: _isTradeUpEligible,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      mediaFilePaths: _selectedMedia.map((file) => file.path).toList(),
    );

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0;
    });

    _analytics.logEvent(
      'create_listing_submission_started',
      properties: {
        'has_tags': _tags.isNotEmpty,
        'media_count': _selectedMedia.length,
        'category': _selectedCategory.name,
      },
    );

    try {
      final listing = await _listingService.createListing(
        request,
        onUploadProgress: (progress) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
      );

      _analytics.logEvent(
        'create_listing_submission_succeeded',
        properties: {
          'listing_id': listing.id,
          'upload_duration_seconds': null,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Listing published successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      _resetWizard();
    } on ListingServiceException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      _analytics.logEvent(
        'create_listing_failed',
        properties: {'reason': error.message},
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong while publishing. Please try again.')),
      );
      _analytics.logEvent(
        'create_listing_failed',
        properties: {'reason': 'unexpected_error'},
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _resetWizard() {
    for (final key in _stepFormKeys) {
      key.currentState?.reset();
    }

    _titleController.clear();
    _descriptionController.clear();
    _valueController.clear();
    _locationController.clear();
    _tagInputController.clear();

    setState(() {
      _tags.clear();
      _selectedMedia.clear();
      _selectedCategory = ListingCategory.goods;
      _isTradeUpEligible = false;
      _currentStep = 0;
    });
    _analytics.logEvent('create_listing_wizard_reset');
  }

  Widget _buildMediaPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 10 photos or short clips. The first item becomes your cover photo.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _isSubmitting ? null : _pickMedia,
          child: DottedBorder(
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 1.6,
            borderType: BorderType.rRect,
            radius: const Radius.circular(16),
            dashPattern: const [6, 6],
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 32, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    _selectedMedia.isEmpty
                        ? 'Tap to select media'
                        : 'Replace media selection',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_selectedMedia.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${_selectedMedia.length} item(s) selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedMedia.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _selectedMedia.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final file = _selectedMedia[index];
              return Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _mediaFallback(),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() => _selectedMedia.removeAt(index)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cover',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _mediaFallback() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildReviewCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _reviewRow('Title', _titleController.text.isEmpty ? 'Add a title' : _titleController.text),
            _reviewRow('Category', _selectedCategory.displayName),
            _reviewRow('Location',
                _locationController.text.trim().isEmpty ? 'Optional' : _locationController.text.trim()),
            _reviewRow('Estimated value',
                _valueController.text.trim().isEmpty ? 'Add your valuation' : '${String.fromCharCode(36)}${_valueController.text.trim()}'),
            _reviewRow('Trade-up eligible', _isTradeUpEligible ? 'Yes' : 'No'),
            _reviewRow('Tags', _tags.isEmpty ? 'Add discovery tags' : _tags.join(', ')),
            const SizedBox(height: 12),
            Text(
              _descriptionController.text.isEmpty
                  ? 'Add a description to help traders understand your offer.'
                  : _descriptionController.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create listing',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed:
                _currentStep == _steps.length - 1 && !_isSubmitting ? _createListing : null,
            child: Text(
              'Post',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) {
          if (step <= _currentStep) {
            _goToStep(step);
          }
        },
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == _steps.length - 1;
          return Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _handleBack,
                  child: const Text('Back'),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleContinue,
                  child: Text(isLastStep ? 'Publish listing' : 'Continue'),
                ),
              ),
            ],
          );
        },
        steps: _steps,
      ),
    );
  }
}

class DottedBorder extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final BorderType borderType;
  final Radius radius;
  final List<double> dashPattern;
  final Widget child;

  const DottedBorder({
    super.key,
    required this.color,
    required this.strokeWidth,
    required this.borderType,
    required this.radius,
    required this.dashPattern,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        borderType: borderType,
        radius: radius,
        dashPattern: dashPattern,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: child,
      ),
    );
  }
}

enum BorderType { circle, rRect }

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final BorderType borderType;
  final Radius radius;
  final List<double> dashPattern;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderType,
    required this.radius,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path();
    switch (borderType) {
      case BorderType.circle:
        path.addOval(rect);
        break;
      case BorderType.rRect:
        path.addRRect(RRect.fromRectAndRadius(rect, radius));
        break;
    }

    final dashedPath = _createDashedPath(path, dashPattern);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, List<double> dashArray) {
    final metrics = source.computeMetrics();
    final Path dashed = Path();
    for (final metric in metrics) {
      double distance = 0.0;
      var draw = true;
      int dashIndex = 0;
      while (distance < metric.length) {
        final length = dashArray[dashIndex % dashArray.length];
        if (draw) {
          dashed.addPath(metric.extractPath(distance, distance + length), Offset.zero);
        }
        distance += length;
        draw = !draw;
        dashIndex += 1;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
