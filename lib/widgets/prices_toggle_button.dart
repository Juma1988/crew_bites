import 'package:flutter/material.dart';

import '../core/app_haptics.dart';
import '../core/states/app_settings.dart';
import '../core/translate.dart';
import '../core/values/app_values.dart';

/// Prices control: icon + label, green when on (F12 discoverability).
class PricesToggleButton extends StatelessWidget {
  const PricesToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        final t = Translate.instance;
        final on = settings.pricesEnabled;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final color = on
            ? (isDark ? AppValues.pricesOnDark : AppValues.pricesOn)
            : (isDark ? Colors.white54 : AppValues.pricesOff);

        return Semantics(
          button: true,
          toggled: on,
          label: on ? t.pricesOnHint : t.pricesOffHint,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                AppHaptics.selectionClick();
                settings.togglePrices();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppValues.minTouchCompact,
                  minHeight: AppValues.minTouchCompact,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        on
                            ? Icons.payments_rounded
                            : Icons.money_off_csred_rounded,
                        size: 20,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      AnimatedDefaultTextStyle(
                        duration: AppValues.animFast,
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: AppValues.pricesFontSize,
                          letterSpacing: 0.3,
                          color: color,
                        ),
                        child: Text(t.pricesLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
