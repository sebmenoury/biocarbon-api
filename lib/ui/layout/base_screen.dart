import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final String title;
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
    final Widget content;

    if (child != null) {
      content = child!;
    } else if (children != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children!,
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFECF2FE), Colors.white],
          ),
        ),
        child: ListView(padding: const EdgeInsets.all(14), children: [content]),
      ),
    );
  }
}
