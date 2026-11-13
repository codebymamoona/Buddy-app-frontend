import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Shared building blocks for the redesigned screens (lib/widgets/buddy_widgets.dart).
// Names are prefixed "Buddy" so they never clash with the older helpers in common.dart
// (PrimaryButton, FormCard, SectionHeader, BuddyAppBar), which keep working until the
// screens that use them are migrated.

/// Lavender gradient behind a whole screen. Use as the Scaffold body's root.
class BuddyBackground extends StatelessWidget {
  final Widget child;
  const BuddyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appBackground),
      child: SizedBox.expand(child: child),
    );
  }
}

/// White rounded card with the design's border and soft shadow.
class BuddyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool shadow;

  const BuddyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadow ? AppColors.cardShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small uppercase label ("YOUR ASSISTANT", "SMART SPENDING").
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  const Eyebrow(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppText.eyebrow.copyWith(color: color));
  }
}

/// 44x44 square icon button used for back / add / close in headers.
class BuddyIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const BuddyIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(13));
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: shape.copyWith(side: const BorderSide(color: AppColors.border)),
        child: InkWell(
          customBorder: shape,
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: iconColor ?? AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Eyebrow + title row with optional leading / trailing widgets. Handles the status bar inset.
class BuddyScreenHeader extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool useSafeArea;

  const BuddyScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.leading,
    this.trailing,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 3)],
                Text(title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
    return useSafeArea ? SafeArea(bottom: false, child: row) : row;
  }
}

/// Full-width solid purple button with the design's glow. Pass onPressed: null to disable.
class BuddyPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  const BuddyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(AppRadius.control);
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: radius,
            boxShadow: AppColors.buttonShadow,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: Center(
                child: loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White button with a border. danger: true gives the red "Deny" look.
class BuddyOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final double height;

  const BuddyOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      side: BorderSide(color: danger ? AppColors.danger : AppColors.border, width: danger ? 1.5 : 1.3),
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
        opacity: onPressed == null ? 0.45 : 1,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Material(
            color: AppColors.surface,
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.button.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum BuddyStatus { executed, approved, drafted, pending, rejected, expired }

/// Small uppercase status badge (EXECUTED, DRAFTED, REJECTED, EXPIRED, PENDING, APPROVED).
class StatusPill extends StatelessWidget {
  final String label;
  final BuddyStatus status;

  const StatusPill({super.key, required this.label, required this.status});

  (Color, Color) _palette() => switch (status) {
    BuddyStatus.executed || BuddyStatus.approved => (AppColors.success, AppColors.successBg),
    BuddyStatus.drafted || BuddyStatus.pending => (AppColors.warning, AppColors.warningBg),
    BuddyStatus.rejected => (AppColors.danger, AppColors.dangerBg),
    BuddyStatus.expired => (AppColors.expired, AppColors.expiredBg),
  };

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _palette();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          height: 1.2,
          color: fg,
        ),
      ),
    );
  }
}

/// Selectable pill (interests, audit filters). Minimum 40dp tall for touch.
class BuddyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const BuddyChip({super.key, required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? const Color(0xFFC9B0EC) : AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.primaryDark),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppFonts.body,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon + optional title + message in a soft tinted box.
/// Defaults to soft purple; pass warning colors for "your approval is required".
class BuddyNotice extends StatelessWidget {
  final IconData icon;
  final String? title;
  final String message;
  final Color background;
  final Color borderColor;
  final Color accent;

  const BuddyNotice({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.background = AppColors.primarySoft,
    this.borderColor = AppColors.primaryBorder,
    this.accent = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: AppText.bodyStrong.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                ],
                Text(message, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static gradient orb: Buddy's avatar in chat and the placeholder for the animated orb.
class MiniOrb extends StatelessWidget {
  final double size;
  const MiniOrb({super.key, this.size = 29});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.5),
            radius: 0.95,
            colors: [Colors.white, Color(0xFFB79AEE), Color(0xFFC5E9F8), Color(0xFFC199ED)],
            stops: [0.0, 0.35, 0.6, 1.0],
          ),
          boxShadow: [BoxShadow(color: Color(0xFFD5C1F6), blurRadius: 9)],
        ),
      ),
    );
  }
}

class BuddyNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int badge; // 0 hides the badge

  const BuddyNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge = 0,
  });
}

/// Floating frosted pill navigation (Chat / Approve / Wallet).
/// Put it in Scaffold.bottomNavigationBar and give scroll views ~96dp of bottom padding.
class BuddyBottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<BuddyNavItem> items;

  const BuddyBottomNav({
    super.key,
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: AppColors.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: Colors.white),
                ),
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: 1.0,
                  maxScaleFactor: 1.15,
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: i == index,
                            onTap: () => onChanged(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final BuddyNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.badge > 0 ? '${item.label}, ${item.badge} pending' : item.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 31,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 20,
                    color: selected ? Colors.white : color,
                  ),
                ),
                if (item.badge > 0)
                  Positioned(top: -5, right: -3, child: _CountBadge(count: item.badge)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.body,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );
  }
}