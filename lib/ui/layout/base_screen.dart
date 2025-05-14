import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final Widget title;
  final Widget? child;
  final List<Widget>? children;
  final List<Widget>? actions;

  const BaseScreen({
    super.key,
    required this.title,
    this.child,
    this.children,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECF2FE), Colors.white],
          ),
        ),
        child:
            child != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: title,
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: child!),
                  ],
                )
                : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: title,
                    ),
                    const SizedBox(height: 12),
                    if (children != null) ...children!,
                  ],
                ),
      ),
    );
  }
}
