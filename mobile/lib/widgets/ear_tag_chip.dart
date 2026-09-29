import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// The yellow Indian livestock ear tag: a wide body, a narrower rounded tab
/// on top, and a punched hole in the tab. The app's signature shape.
class EarTagBorder extends ShapeBorder {
  const EarTagBorder({this.tabHeight = 10, this.edge = const BorderSide(color: AppColors.ink, width: 1)});

  final double tabHeight;
  final BorderSide edge;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(top: tabHeight);

  Path _outline(Rect rect) {
    final bodyRadius = Radius.circular(tabHeight * 0.7);
    final body = RRect.fromRectAndRadius(
        Rect.fromLTRB(rect.left, rect.top + tabHeight, rect.right, rect.bottom), bodyRadius);
    final tabWidth = rect.width * 0.36;
    final tab = RRect.fromRectAndCorners(
      Rect.fromCenter(
          center: Offset(rect.center.dx, rect.top + tabHeight), width: tabWidth, height: tabHeight * 2),
      topLeft: Radius.circular(tabHeight),
      topRight: Radius.circular(tabHeight),
    );
    return Path.combine(PathOperation.union, Path()..addRRect(body), Path()..addRRect(tab));
  }

  Path _hole(Rect rect) => Path()
    ..addOval(Rect.fromCircle(center: Offset(rect.center.dx, rect.top + tabHeight * 0.75), radius: tabHeight * 0.32));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path.combine(PathOperation.difference, _outline(rect), _hole(rect));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (edge.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect), edge.toPaint());
  }

  @override
  ShapeBorder scale(double t) => EarTagBorder(tabHeight: tabHeight * t, edge: edge.scale(t));
}

enum EarTagSize { small, large }

/// Animal ID as a yellow ear tag, number grouped like `1234 5678 9012`.
class EarTagChip extends StatelessWidget {
  const EarTagChip(this.number, {super.key, this.size = EarTagSize.small});

  final String number;
  final EarTagSize size;

  static String group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final large = size == EarTagSize.large;
    final base = Theme.of(context).textTheme.displayLarge!;
    final style = base.copyWith(fontSize: large ? 24 : 14, height: 1.2, color: AppColors.ink);
    final grouped = group(number);
    return Semantics(
      label: 'Ear tag $grouped',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.fromLTRB(large ? 16 : 8, large ? 6 : 3, large ? 16 : 8, large ? 8 : 4),
        decoration: ShapeDecoration(
          color: AppColors.tagYellow,
          shape: EarTagBorder(tabHeight: large ? 14 : 8),
        ),
        child: Text(grouped, style: style, maxLines: 1, softWrap: false),
      ),
    );
  }
}
