import 'package:flutter/material.dart';

String localizedText(
  BuildContext context, {
  required String en,
  String? mr,
}) {
  final languageCode = Localizations.localeOf(context).languageCode.toLowerCase();
  if (languageCode.startsWith('mr') && mr != null && mr.isNotEmpty) {
    return mr;
  }
  return en;
}


