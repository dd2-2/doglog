import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card를 대체하는 뉴모피즘(소프트 UI) 스타일 컨테이너.
/// 밝은 하이라이트(좌상단) + 어두운 그림자(우하단)를 동시에 줘서
/// 배경 위에 살짝 볼록하게 떠있는 느낌을 만든다.
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
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-6, -6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.14),
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
