import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Spec §5.10 — bottom sheet wrapper.
///
/// Standardizes title row, optional close button, sticky bottom action bar.
class VedgeSheetScaffold extends StatelessWidget {
  const VedgeSheetScaffold({
    required this.title,
    required this.child,
    this.bottomActions,
    this.onClose,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? bottomActions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VedgeSpacing.space6,
                VedgeSpacing.space4,
                VedgeSpacing.space6,
                VedgeSpacing.space2,
              ),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: t.titleLarge)),
                  if (onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      onPressed: onClose,
                      iconSize: 24,
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VedgeSpacing.space6,
                  0,
                  VedgeSpacing.space6,
                  VedgeSpacing.space4,
                ),
                child: child,
              ),
            ),
            if (bottomActions != null && bottomActions!.isNotEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(top: BorderSide(color: cs.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VedgeSpacing.space6,
                      vertical: VedgeSpacing.space3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final w in bottomActions!) ...[
                          w,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: media.padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Helper for opening a Vedge-styled bottom sheet.
Future<T?> showVedgeSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
  List<Widget>? bottomActions,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => VedgeSheetScaffold(
      title: title,
      bottomActions: bottomActions,
      onClose: onClose ?? () => Navigator.of(ctx).maybePop(),
      child: builder(ctx),
    ),
  );
}
