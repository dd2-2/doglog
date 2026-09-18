import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card를 대체하는 클리어한 화이트 카드: 얇은 보더 + 미니멀한 단일 그림자로 깔끔하게 구분.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.margin});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            offset: const Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
