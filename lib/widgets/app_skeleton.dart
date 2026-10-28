import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// هيكل تحميل باستخدام مكتبة shimmer.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 10,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A3530) : const Color(0xFFE4EAE6);
    final highlight = isDark ? const Color(0xFF3D4A44) : const Color(0xFFF5F8F6);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// قائمة هياكل لقوائم السور/الآيات أثناء التحميل.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.count = 8});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 48, height: 48, borderRadius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(height: 16, width: 160),
                SizedBox(height: 10),
                AppSkeleton(height: 12, width: double.infinity),
                SizedBox(height: 8),
                AppSkeleton(height: 12, width: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
