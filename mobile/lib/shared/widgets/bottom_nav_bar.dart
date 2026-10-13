import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_shadows.dart';

class LiquidGlassBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LiquidGlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<LiquidGlassBottomNav> createState() => _LiquidGlassBottomNavState();
}

class _LiquidGlassBottomNavState extends State<LiquidGlassBottomNav> {
  int? _hoveredIndex;
  Offset? _pointerDownPos;
  bool _isDragging = false;

  int _getIndexFromPosition(double localX, double totalWidth) {
    if (totalWidth <= 0) return widget.currentIndex;
    final itemWidth = totalWidth / 5.0;
    return (localX / itemWidth).floor().clamp(0, 4);
  }

  void _onPointerDown(PointerDownEvent event, double totalWidth) {
    _pointerDownPos = event.localPosition;
    _isDragging = false;
    _hoveredIndex = _getIndexFromPosition(event.localPosition.dx, totalWidth);
  }

  void _onPointerMove(PointerMoveEvent event, double totalWidth) {
    if (_pointerDownPos == null) return;
    final delta = (event.localPosition - _pointerDownPos!).distance;
    if (delta > 8.0) {
      if (!_isDragging) {
        _isDragging = true;
      }
      // Cancel if dragged far outside vertically
      if (event.localPosition.dy < -50 || event.localPosition.dy > 110) {
        if (_hoveredIndex != null) {
          setState(() => _hoveredIndex = null);
        }
        return;
      }

      final newIdx = _getIndexFromPosition(event.localPosition.dx, totalWidth);
      if (newIdx != _hoveredIndex) {
        HapticFeedback.selectionClick();
        setState(() => _hoveredIndex = newIdx);
      }
    }
  }

  void _onPointerUp(PointerUpEvent event, double totalWidth) {
    if (_isDragging && _hoveredIndex != null) {
      final target = _hoveredIndex!;
      setState(() {
        _hoveredIndex = null;
        _isDragging = false;
        _pointerDownPos = null;
      });
      widget.onTap(target);
    } else {
      setState(() {
        _hoveredIndex = null;
        _isDragging = false;
        _pointerDownPos = null;
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _hoveredIndex = null;
      _isDragging = false;
      _pointerDownPos = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveIndex = _hoveredIndex ?? widget.currentIndex;

    Widget buildNavRow() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Dashboard', effectiveIndex)),
          Expanded(child: _buildNavItem(1, Icons.schedule_rounded, 'Routine', effectiveIndex)),
          Expanded(child: _buildNavItem(2, Icons.pie_chart_outline_rounded, 'Analytics', effectiveIndex)),
          Expanded(child: _buildNavItem(3, Icons.menu_book_rounded, 'Subjects', effectiveIndex)),
          Expanded(child: _buildNavItem(4, Icons.beach_access_rounded, 'Holidays', effectiveIndex)),
        ],
      );
    }

    final navContainer = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) => _onPointerDown(e, totalWidth),
          onPointerMove: (e) => _onPointerMove(e, totalWidth),
          onPointerUp: (e) => _onPointerUp(e, totalWidth),
          onPointerCancel: _onPointerCancel,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: kIsWeb ? 0.95 : 0.88),
              borderRadius: AppRadii.radiusPill,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
              boxShadow: AppShadows.floating,
            ),
            child: buildNavRow(),
          ),
        );
      },
    );

    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ClipRRect(
            borderRadius: AppRadii.radiusPill,
            child: kIsWeb
                ? navContainer
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: navContainer,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int selectedIndex) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 10 : 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.terracotta.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: AppRadii.radiusPill,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.terracotta : AppColors.inkMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.terracotta : AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
