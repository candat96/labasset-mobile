import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_card.dart';

/// Khung màn auth: nửa trên hero gradient bo dưới 32 (logo trong tròn trắng
/// 96 + "MedOne" 28/800), form card nổi đè lên hero (offset -32).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  static const _overlap = 32.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const white = AppColors.onPrimary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  top + AppSpacing.sm,
                  AppSpacing.lg,
                  _overlap + AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  gradient: context.brandGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: showBack
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).backButtonTooltip,
                                icon: Icon(
                                  LucideIcons.chevronLeft,
                                  color: white,
                                ),
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x33000000),
                            offset: const Offset(0, 8),
                            blurRadius: 24,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/brand/medone-logo.png',
                        width: 200,
                        height: 150,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: context.appText.label.copyWith(
                          color: white.withValues(alpha: 0.85),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -_overlap),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: AppCard(
                        floating: true,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(title, style: context.appText.title),
                            const SizedBox(height: AppSpacing.lg),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
