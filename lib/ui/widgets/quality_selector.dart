import 'package:flutter/material.dart';

import '../../data/data_budget.dart';

/// Lets the operator pick the data budget before going live.
/// Shows MB/hour and the quality that budget will produce, so the
/// decision is made with real numbers.
class QualitySelector extends StatelessWidget {
  final BudgetMode value;
  final ValueChanged<BudgetMode> onChanged;

  const QualitySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF14141A),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DATA BUDGET',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          ...BudgetMode.values.map((m) {
            final selected = m == value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onChanged(m),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.blueAccent.withOpacity(0.12)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.blueAccent
                          : Colors.white12,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? Colors.blueAccent
                              : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? Colors.blueAccent
                                : Colors.white38,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.black,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  m.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    m.quality,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white70,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              m.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white54,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
