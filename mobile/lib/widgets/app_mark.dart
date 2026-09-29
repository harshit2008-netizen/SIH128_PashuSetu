import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/theme/tokens.dart';
import '../l10n/app_localizations.dart';

/// The ear-tag app mark next to the app name, used in app bars.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 32, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final name = AppLocalizations.of(context).appName;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/pictograms/app_mark.svg', width: size, height: size, excludeFromSemantics: true),
        if (showName) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(name, style: Theme.of(context).textTheme.titleLarge),
        ],
      ],
    );
  }
}
