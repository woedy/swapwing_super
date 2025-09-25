import 'package:flutter/material.dart';
import 'package:swapwing/models/journey_draft.dart';
import 'package:swapwing/models/listing.dart';
import 'package:swapwing/models/trade_journey.dart';
import 'package:swapwing/screens/social/journey_detail_screen.dart';
import 'package:swapwing/services/analytics_service.dart';
import 'package:swapwing/services/journey_service.dart';
import 'package:swapwing/services/sample_data.dart';
import 'package:swapwing/widgets/journey_card.dart';

class JourneyComposerResult {
  final JourneyDraft? savedDraft;
  final TradeJourney? publishedJourney;

  const JourneyComposerResult({this.savedDraft, this.publishedJourney});

  bool get didPublish => publishedJourney != null;
}

class JourneyComposerScreen extends StatefulWidget {
  final JourneyDraft? initialDraft;

  const JourneyComposerScreen({super.key, this.initialDraft});

  @override
  State<JourneyComposerScreen> createState() => _JourneyComposerScreenState();
}

class _JourneyComposerScreenState extends State<JourneyComposerScreen> {
  final _basicsFormKey = GlobalKey<FormState>();
  final _storyFormKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _startingValueController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _tagInputController = TextEditingController();

  final JourneyService _journeyService = const JourneyService();
  final AnalyticsService _analytics = AnalyticsService.instance;

  late JourneyDraft _draft;
  int _currentStep = 0;
  bool _savingDraft = false;
  bool _publishing = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft ?? JourneyDraft.empty();
    _titleController.text = _draft.title ?? '';
    _descriptionController.text = _draft.description ?? '';
    if (_draft.startingValue != null) {
      _startingValueController.text = _formatCurrencyInput(_draft.startingValue!);
    }
    if (_draft.targetValue != null) {
      _targetValueController.text = _formatCurrencyInput(_draft.targetValue!);
    }
    _analytics.logEvent(
      'journey_composer_opened',
      properties: {
        'draft_id': _draft.id,
        'has_initial_data': widget.initialDraft != null,
        'step_count': _draft.steps.length,
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startingValueController.dispose();
    _targetValueController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _handleExitRequested();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final canLeave = await _handleExitRequested();
              if (canLeave && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: const Text('Compose Journey'),
          actions: [
            TextButton.icon(
              onPressed: _savingDraft ? null : _saveDraft,
              icon: _savingDraft
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Draft'),
            ),
          ],
        ),
        body: Stepper(
          currentStep: _currentStep,
          type: StepperType.vertical,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: _publishing ? null : _goToPreviousStep,
                      child: const Text('Back'),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _currentStep == _steps.length - 1
                        ? ElevatedButton.icon(
                            onPressed: _publishing ? null : _publishJourney,
                            icon: _publishing
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.rocket_launch),
                            label: const Text('Publish Journey'),
                          )
                        : ElevatedButton(
                            onPressed: _goToNextStep,
                            child: const Text('Continue'),
                          ),
                  ),
                ],
              ),
            );
          },
          steps: _steps,
        ),
      ),
    );
  }

  List<Step> get _steps => [
        Step(
          title: const Text('Basics'),
          state: _stepStateFor(0),
          isActive: _currentStep >= 0,
          content: Form(
            key: _basicsFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    label: 'Journey title',
                    hint: 'What adventure are you starting?',
                  ),
                  onChanged: (value) => _updateDraft(
                    (draft) => draft.copyWith(title: value, touchUpdatedAt: true),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Give your journey a name to help others discover it.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormField<SwapListing?>(
                  validator: (_) {
                    if (_draft.startingListingId == null && _draft.startingListing == null) {
                      return 'Select a starting listing to launch your journey.';
                    }
                    return null;
                  },
                  builder: (field) {
                    final listing = _draft.startingListing;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting item',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _selectStartingListing,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: field.hasError
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                              ),
                              color: Theme.of(context).colorScheme.surfaceContainerLowest,
                            ),
                            child: listing == null
                                ? Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Choose a listing to trade up from',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Theme.of(context).colorScheme.surface,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: listing.primaryImageUrl != null
                                            ? Image.network(
                                                listing.primaryImageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              )
                                            : Icon(
                                                Icons.inventory,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              listing.title,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            if (listing.estimatedValue != null)
                                              Text(
                                                'Est. value ${_formatCurrency(listing.estimatedValue!)}',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Change starting item',
                                        onPressed: _selectStartingListing,
                                        icon: const Icon(Icons.swap_horiz),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        if (field.hasError) ...[
                          const SizedBox(height: 8),
                          Text(
                            field.errorText ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startingValueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(
                          label: 'Starting value',
                          prefixText: '\$',
                        ),
                        onChanged: (value) => _updateDraft(
                          (draft) => draft.copyWith(
                            startingValue: double.tryParse(value.replaceAll(',', '').trim()),
                            touchUpdatedAt: true,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Estimate the value of your starting item.';
                          }
                          if (double.tryParse(value.replaceAll(',', '').trim()) == null) {
                            return 'Enter a valid number.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _targetValueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(
                          label: 'Target value',
                          prefixText: '\$',
                        ),
                        onChanged: (value) => _updateDraft(
                          (draft) => draft.copyWith(
                            targetValue: double.tryParse(value.replaceAll(',', '').trim()),
                            touchUpdatedAt: true,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Set a goal to track your progress.';
                          }
                          final parsed = double.tryParse(value.replaceAll(',', '').trim());
                          if (parsed == null) {
                            return 'Enter a valid number.';
                          }
                          if (parsed <= 0) {
                            return 'Target value must be greater than zero.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Story'),
          state: _stepStateFor(1),
          isActive: _currentStep >= 1,
          content: Form(
            key: _storyFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: _inputDecoration(
                    label: 'Narrative',
                    hint: 'Share the mission and what you hope to trade into...',
                  ),
                  onChanged: (value) => _updateDraft(
                    (draft) => draft.copyWith(description: value, touchUpdatedAt: true),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _tagInputController,
                  decoration: _inputDecoration(
                    label: 'Add tags',
                    hint: 'Hit enter after each tag',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _handleTagSubmitted(value),
                ),
                if (_draft.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _draft.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Draft steps',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: _showStepEditor,
                      icon: const Icon(Icons.add),
                      label: const Text('Add step'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_draft.steps.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.surfaceContainerLowest,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Map your trade-up plan',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Outline the steps you expect to take. Mark completed steps to include them in your published story.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _draft.steps
                        .map(
                          (step) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Text('${_draft.steps.indexOf(step) + 1}'),
                              ),
                              title: Text(step.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (step.targetValue != null)
                                    Text('Target value: ${_formatCurrency(step.targetValue!)}'),
                                  if (step.notes?.isNotEmpty == true) Text(step.notes!),
                                  Text(step.isCompleted ? 'Marked as complete' : 'Planned'),
                                ],
                              ),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: step.isCompleted
                                        ? 'Mark as planned'
                                        : 'Mark as completed',
                                    onPressed: () => _toggleStepCompletion(step),
                                    icon: Icon(
                                      step.isCompleted
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: step.isCompleted
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit step',
                                    onPressed: () => _showStepEditor(existing: step),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove step',
                                    onPressed: () => _removeStep(step),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
        Step(
          title: const Text('Preview'),
          state: _stepStateFor(2),
          isActive: _currentStep >= 2,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_draft.isPublishable)
                JourneyCard(journey: _draft.toTradeJourney(SampleData.currentUser))
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    'Complete the basics step to generate a full preview.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _draft.isPublishable ? _openFullPreview : null,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Open detailed preview'),
              ),
              const SizedBox(height: 24),
              _buildSummaryTile(
                icon: Icons.flag_outlined,
                label: 'Target value',
                value: _draft.targetValue != null
                    ? _formatCurrency(_draft.targetValue!)
                    : 'Set in basics step',
              ),
              _buildSummaryTile(
                icon: Icons.inventory_2_outlined,
                label: 'Starting item',
                value: _draft.startingListing?.title ?? 'Select an item',
              ),
              _buildSummaryTile(
                icon: Icons.timeline_outlined,
                label: 'Steps outlined',
                value: '${_draft.steps.length} (${_draft.steps.where((s) => s.isCompleted).length} completed)',
              ),
            ],
          ),
        ),
      ];

  StepState _stepStateFor(int step) {
    if (_currentStep > step) {
      return StepState.complete;
    }
    if (_currentStep == step) {
      return StepState.editing;
    }
    return StepState.indexed;
  }

  Future<void> _goToNextStep() async {
    if (_currentStep == 0) {
      if (!(_basicsFormKey.currentState?.validate() ?? false)) {
        _analytics.logEvent(
          'journey_composer_step_validation_failed',
          properties: {'step': _currentStep},
        );
        return;
      }
    }
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep += 1);
      _analytics.logEvent(
        'journey_composer_step_changed',
        properties: {'step': _currentStep},
      );
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
      _analytics.logEvent(
        'journey_composer_step_changed',
        properties: {'step': _currentStep},
      );
    }
  }

  Future<void> _saveDraft() async {
    FocusScope.of(context).unfocus();
    setState(() => _savingDraft = true);
    try {
      final saved = await _journeyService.saveDraft(_draft);
      if (!mounted) return;
      setState(() {
        _draft = saved;
        _savingDraft = false;
        _hasUnsavedChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft saved'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      _analytics.logEvent(
        'journey_draft_saved',
        properties: {
          'draft_id': saved.id,
          'step_count': saved.steps.length,
        },
      );
    } on JourneyServiceException catch (error) {
      if (!mounted) return;
      setState(() => _savingDraft = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _analytics.logEvent(
        'journey_draft_save_failed',
        properties: {
          'draft_id': _draft.id,
          'reason': error.message,
        },
      );
    }
  }

  Future<void> _publishJourney() async {
    FocusScope.of(context).unfocus();
    if (!(_basicsFormKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0);
      _analytics.logEvent(
        'journey_publish_validation_failed',
        properties: {'draft_id': _draft.id, 'reason': 'basics_invalid'},
      );
      return;
    }

    if (!_draft.isPublishable) {
      setState(() => _currentStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Finish the basics to publish your journey.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _analytics.logEvent(
        'journey_publish_validation_failed',
        properties: {'draft_id': _draft.id, 'reason': 'incomplete_draft'},
      );
      return;
    }

    setState(() => _publishing = true);
    _analytics.logEvent(
      'journey_publish_attempted',
      properties: {
        'draft_id': _draft.id,
        'step_count': _draft.steps.length,
      },
    );
    try {
      final journey = await _journeyService.publishJourney(_draft);
      if (!mounted) return;
      setState(() {
        _publishing = false;
        _hasUnsavedChanges = false;
      });
      _analytics.logEvent(
        'journey_published',
        properties: {
          'draft_id': _draft.id,
          'journey_id': journey.id,
        },
      );
      Navigator.of(context).pop(
        JourneyComposerResult(publishedJourney: journey),
      );
    } on JourneyServiceException catch (error) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      _analytics.logEvent(
        'journey_publish_failed',
        properties: {
          'draft_id': _draft.id,
          'reason': error.message,
        },
      );
    }
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
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _updateDraft(JourneyDraft Function(JourneyDraft) mutation) {
    setState(() {
      _draft = mutation(_draft);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _selectStartingListing() async {
    final listings = SampleData.getListingsForUser(SampleData.currentUser.id);
    _analytics.logEvent(
      'journey_starting_listing_picker_opened',
      properties: {'listing_count': listings.length},
    );
    if (!mounted) return;
    final selected = await showModalBottomSheet<SwapListing?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: listings.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 32),
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create a listing first',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Publish a listing to use it as the foundation of your journey.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select starting listing',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...listings.map(
                        (listing) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            child: listing.primaryImageUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      listing.primaryImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        Icons.image_outlined,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.inventory,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                          ),
                          title: Text(listing.title),
                          subtitle: listing.estimatedValue != null
                              ? Text('Est. value ${_formatCurrency(listing.estimatedValue!)}')
                              : null,
                          onTap: () => Navigator.of(context).pop(listing),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );

    if (selected != null) {
      _startingValueController.text = selected.estimatedValue != null
          ? _formatCurrencyInput(selected.estimatedValue!)
          : '';
      _updateDraft(
        (draft) => draft.copyWith(
          startingListing: selected,
          startingListingId: selected.id,
          startingValue: selected.estimatedValue,
          touchUpdatedAt: true,
        ),
      );
      _analytics.logEvent(
        'journey_starting_listing_selected',
        properties: {'listing_id': selected.id},
      );
    }
  }

  void _handleTagSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _tagInputController.clear();
    _updateDraft((draft) {
      final tags = List<String>.from(draft.tags);
      final normalized = trimmed.toLowerCase();
      final existing = tags.map((tag) => tag.toLowerCase()).toSet();
      if (!existing.contains(normalized)) {
        tags.add(trimmed);
      }
      return draft.copyWith(tags: tags, touchUpdatedAt: true);
    });
  }

  void _removeTag(String tag) {
    _updateDraft((draft) {
      final tags = List<String>.from(draft.tags)..remove(tag);
      return draft.copyWith(tags: tags, touchUpdatedAt: true);
    });
  }

  void _toggleStepCompletion(JourneyDraftStep step) {
    _updateDraft((draft) {
      final steps = List<JourneyDraftStep>.from(draft.steps);
      final index = steps.indexWhere((element) => element.id == step.id);
      if (index == -1) return draft;
      steps[index] = steps[index].markCompleted(!steps[index].isCompleted);
      return draft.copyWith(steps: steps, touchUpdatedAt: true);
    });
    _analytics.logEvent(
      'journey_step_completion_toggled',
      properties: {
        'draft_id': _draft.id,
        'step_id': step.id,
      },
    );
  }

  void _removeStep(JourneyDraftStep step) {
    _updateDraft((draft) {
      final steps = List<JourneyDraftStep>.from(draft.steps)..removeWhere((element) => element.id == step.id);
      return draft.copyWith(steps: steps, touchUpdatedAt: true);
    });
    _analytics.logEvent(
      'journey_step_removed',
      properties: {
        'draft_id': _draft.id,
        'step_id': step.id,
      },
    );
  }

  Future<void> _showStepEditor({JourneyDraftStep? existing}) async {
    _analytics.logEvent(
      'journey_step_editor_opened',
      properties: {
        'draft_id': _draft.id,
        'is_edit': existing != null,
      },
    );
    final titleController = TextEditingController(text: existing?.title ?? '');
    final valueController = TextEditingController(
      text: existing?.targetValue != null ? _formatCurrencyInput(existing!.targetValue!) : '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var isCompleted = existing?.isCompleted ?? false;

    final result = await showModalBottomSheet<JourneyDraftStep?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add step' : 'Edit step',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Step title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target value',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setSheetState) {
                  return SwitchListTile.adaptive(
                    value: isCompleted,
                    onChanged: (value) {
                      setSheetState(() => isCompleted = value);
                    },
                    title: const Text('Mark as completed'),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) {
                          Navigator.of(context).pop(null);
                          return;
                        }
                        Navigator.of(context).pop(
                          JourneyDraftStep(
                            id: existing?.id ?? 'draft_step_${DateTime.now().millisecondsSinceEpoch}',
                            title: titleController.text.trim(),
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                            targetValue: double.tryParse(
                              valueController.text.replaceAll(',', '').trim(),
                            ),
                            isCompleted: isCompleted,
                            createdAt: existing?.createdAt ?? DateTime.now(),
                            completedAt: isCompleted
                                ? existing?.completedAt ?? DateTime.now()
                                : null,
                          ),
                        );
                      },
                      child: Text(existing == null ? 'Add step' : 'Save changes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (result != null) {
      _updateDraft((draft) {
        final steps = List<JourneyDraftStep>.from(draft.steps);
        final index = steps.indexWhere((step) => step.id == result.id);
        if (index >= 0) {
          steps[index] = result;
        } else {
          steps.add(result);
        }
        return draft.copyWith(steps: steps, touchUpdatedAt: true);
      });
      _analytics.logEvent(
        'journey_step_saved',
        properties: {
          'draft_id': _draft.id,
          'step_id': result.id,
          'is_edit': existing != null,
        },
      );
    }
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Future<void> _openFullPreview() async {
    final preview = _draft.toTradeJourney(SampleData.currentUser);
    _analytics.logEvent(
      'journey_preview_opened',
      properties: {
        'draft_id': _draft.id,
        'step_count': _draft.steps.length,
      },
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JourneyDetailScreen(journey: preview),
      ),
    );
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  String _formatCurrencyInput(double value) {
    final formatted = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
    return formatted;
  }

  Future<bool> _handleExitRequested() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    _analytics.logEvent(
      'journey_exit_prompt_shown',
      properties: {'draft_id': _draft.id},
    );
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('You have unsaved changes. Save your draft before exiting?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop(false);
                await _saveDraft();
              },
              child: const Text('Save draft'),
            ),
          ],
        );
      },
    );

    _analytics.logEvent(
      'journey_exit_prompt_closed',
      properties: {
        'draft_id': _draft.id,
        'should_leave': shouldLeave,
      },
    );
    return shouldLeave ?? false;
  }
}
