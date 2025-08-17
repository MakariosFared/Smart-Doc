import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ?? Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading != null
          ? leading
          : automaticallyImplyLeading
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      actions: actions,
      elevation: 2,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
