import 'package:flutter/material.dart';

class SkeletonLoading extends StatefulWidget {
  const SkeletonLoading({super.key});

  @override
  State<SkeletonLoading> createState() => _SkeletonLoadingState();
}

class _SkeletonLoadingState extends State<SkeletonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    final shimmer = theme.colorScheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeroSkeleton(base, shimmer);
            }
            return _buildListItemSkeleton(base, shimmer);
          },
        );
      },
    );
  }

  Widget _buildShimmerOverlay(Color base, Color shimmer) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment(-1 + _controller.value * 2, 0),
          end: Alignment(1 + _controller.value * 2, 0),
          colors: [
            base,
            shimmer,
            base,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcOver,
      child: Container(color: Colors.white),
    );
  }

  Widget _buildHeroSkeleton(Color base, Color shimmer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Gradient overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      base.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            // Text lines at bottom
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLine(base, 0.6, 16),
                  const SizedBox(height: 8),
                  _buildLine(base, 0.9, 20),
                  const SizedBox(height: 8),
                  _buildLine(base, 0.4, 14),
                ],
              ),
            ),
            // Shimmer
            _buildShimmerOverlay(base, shimmer),
          ],
        ),
      ),
    );
  }

  Widget _buildListItemSkeleton(Color base, Color shimmer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Row(
              children: [
                // Thumbnail placeholder
                Container(
                  width: 100,
                  height: 90,
                  color: base,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLine(base, 0.4, 12),
                        const SizedBox(height: 8),
                        _buildLine(base, 0.8, 14),
                        const SizedBox(height: 6),
                        _buildLine(base, 0.5, 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildShimmerOverlay(base, shimmer),
          ],
        ),
      ),
    );
  }

  Widget _buildLine(Color base, double widthFraction, double height) {
    return Container(
      width: MediaQuery.of(context).size.width * widthFraction * 0.5,
      height: height,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
