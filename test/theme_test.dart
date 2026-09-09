import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_101/core/theme.dart';
import 'package:app_101/core/values/app_values.dart';

void main() {
  test('Crew Bites coral theme exposes the persisted semantic palette', () {
    final light = AppTheme.light(ColorPalette.coral).colorScheme;
    expect(light.primary, const Color(0xFFDC2626));
    expect(light.secondary, const Color(0xFFF87171));
    expect(light.tertiary, const Color(0xFFA16207));
    expect(light.surface, const Color(0xFFFEF2F2));
    expect(light.onSurface, const Color(0xFF450A0A));
    expect(light.outline, const Color(0xFFFECACA));
    expect(light.surfaceContainerLow, Colors.white);
  });

  test('dark theme keeps warm surfaces and readable foregrounds', () {
    final dark = AppTheme.dark(ColorPalette.coral).colorScheme;
    expect(dark.brightness, Brightness.dark);
    expect(dark.surface, const Color(0xFF220808));
    expect(dark.onSurface, const Color(0xFFFFF7F7));
    expect(dark.primary, const Color(0xFFF87171));
  });
}
