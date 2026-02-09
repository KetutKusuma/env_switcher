import 'package:flutter/material.dart';
import 'package:env_switcher/src/env_selector_bottom_sheet.dart';

/// Widget that enables environment switching via tap gestures
class EnvSwitcherWidget extends StatefulWidget {
  /// The child widget (usually your logo or app icon)
  final Widget child;

  /// Number of taps required to trigger the environment switcher
  final int requiredTaps;

  /// Time window in which taps must occur (in milliseconds)
  final int tapWindowMs;

  /// Whether the environment switcher is enabled
  final bool enabled;

  /// Callback when environment is changed
  final VoidCallback? onEnvironmentChanged;

  /// Whether app restart is required after switching
  final bool requiresRestart;

  /// Custom title for the bottom sheet
  final String bottomSheetTitle;

  /// Custom subtitle for the bottom sheet
  final String bottomSheetSubtitle;

  /// Whether to show a visual feedback when tap is detected
  final bool showTapFeedback;

  const EnvSwitcherWidget({
    required this.child,
    this.requiredTaps = 5,
    this.tapWindowMs = 3000,
    this.enabled = true,
    this.onEnvironmentChanged,
    this.requiresRestart = true,
    this.bottomSheetTitle = 'Select Environment',
    this.bottomSheetSubtitle = 'Choose the environment you want to use',
    this.showTapFeedback = true,
    super.key,
  });

  @override
  State<EnvSwitcherWidget> createState() => _EnvSwitcherWidgetState();
}

class _EnvSwitcherWidgetState extends State<EnvSwitcherWidget>
    with SingleTickerProviderStateMixin {
  int _tapCount = 0;
  DateTime? _firstTapTime;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled) return;

    final now = DateTime.now();

    // Reset if outside time window
    if (_firstTapTime != null &&
        now.difference(_firstTapTime!).inMilliseconds > widget.tapWindowMs) {
      _tapCount = 0;
      _firstTapTime = null;
    }

    // Record first tap time
    if (_tapCount == 0) {
      _firstTapTime = now;
    }

    _tapCount++;

    // Visual feedback
    if (widget.showTapFeedback) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }

    // Show debug info
    debugPrint('EnvSwitcher: Tap $_tapCount/${widget.requiredTaps}');

    // Trigger environment switcher
    if (_tapCount >= widget.requiredTaps) {
      _showEnvironmentSwitcher();
      _resetTapCount();
    }
  }

  void _resetTapCount() {
    _tapCount = 0;
    _firstTapTime = null;
  }

  void _showEnvironmentSwitcher() {
    // Haptic feedback
    // HapticFeedback.mediumImpact();

    EnvSelectorBottomSheet.show(
      context,
      onEnvironmentChanged: () {
        widget.onEnvironmentChanged?.call();
        _resetTapCount();
      },
      requiresRestart: widget.requiresRestart,
      title: widget.bottomSheetTitle,
      subtitle: widget.bottomSheetSubtitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// A convenient wrapper for adding environment switcher to any widget
class EnvSwitcherDetector extends StatelessWidget {
  final Widget child;
  final int requiredTaps;
  final bool enabled;
  final VoidCallback? onEnvironmentChanged;

  const EnvSwitcherDetector({
    required this.child,
    super.key,
    this.requiredTaps = 5,
    this.enabled = true,
    this.onEnvironmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EnvSwitcherWidget(
      requiredTaps: requiredTaps,
      enabled: enabled,
      onEnvironmentChanged: onEnvironmentChanged,
      child: child,
    );
  }
}
