import 'package:flutter/material.dart';

/// Opens a styled modal bottom sheet with consistent animation and appearance.
///
/// This is the default way to present modal bottom sheets in the app.
/// Provides rounded top corners, 90% screen height limit, and smooth animations.
Future<T?> showMicroMngrBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final double maxHeight = MediaQuery.of(context).size.height * 0.95;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    useRootNavigator: true,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    constraints: BoxConstraints(maxHeight: maxHeight),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 600),
      reverseDuration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),
    builder: builder,
  );
}
