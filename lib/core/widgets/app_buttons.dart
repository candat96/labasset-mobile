import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => _PressScale(
    enabled: onPressed != null && !loading,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, loading: loading),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => _PressScale(
    enabled: onPressed != null && !loading,
    child: OutlinedButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(label: label, icon: icon, loading: loading),
    ),
  );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
  });
  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => loading
      ? const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        );
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled
        ? (_) => setState(() => _pressed = true)
        : null,
    onPointerUp: widget.enabled
        ? (_) => setState(() => _pressed = false)
        : null,
    onPointerCancel: widget.enabled
        ? (_) => setState(() => _pressed = false)
        : null,
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 150),
      child: widget.child,
    ),
  );
}
