import 'package:flutter/material.dart';

import '../theme/spacing.dart';
import 'provider_switcher_chip.dart';

/// Spec §5.11 — standard top app bar.
///
/// Title is rendered with the theme's `titleLarge` (Inter). Provider chip is
/// embedded on the right when [showProviderContext] is true. Onboarding,
/// You-tab and detail screens that don't need provider context pass false.
class VedgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VedgeAppBar({
    required this.title,
    this.showBack = false,
    this.showProviderContext = true,
    this.actions = const [],
    this.onBack,
    super.key,
  });

  final String title;
  final bool showBack;
  final bool showProviderContext;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      titleSpacing: showBack ? 0 : VedgeSpacing.space4,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        if (showProviderContext) ...[
          const ProviderSwitcherChip(),
          const SizedBox(width: VedgeSpacing.space2),
        ],
        ...actions,
        const SizedBox(width: VedgeSpacing.space2),
      ],
    );
  }
}
