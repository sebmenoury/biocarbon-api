import 'package:flutter/material.dart';
import '../../screens/main/mes_donnees_screen.dart';
import '../../screens/main/analyse_screen.dart';
import '../../screens/main/projection_screen.dart';
import '../../screens/main/objectifs_screen.dart';
import '../../screens/main/information_screen.dart';

class AppScaffold extends StatefulWidget {
  const AppScaffold({super.key});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MesDonneesScreen(),
    AnalyseScreen(),
    ProjectionScreen(),
    ObjectifsScreen(),
    InformationScreen(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.edit_note), label: 'Données'),
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Analyse'),
    NavigationDestination(icon: Icon(Icons.timeline), label: 'Projection'),
    NavigationDestination(icon: Icon(Icons.flag), label: 'Objectifs'),
    NavigationDestination(icon: Icon(Icons.info_outline), label: 'Infos'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations:
                  _destinations
                      .map(
                        (e) => NavigationRailDestination(
                          icon: e.icon,
                          label: Text(e.label),
                        ),
                      )
                      .toList(),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar:
          isWide
              ? null
              : Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.black12,
                      width: 0.5,
                    ), // ✅ trait visible
                  ),
                ),
                padding: const EdgeInsets.only(
                  top: 3,
                ), // 👈 rapproche la ligne des icônes
                child: NavigationBar(
                  backgroundColor: Colors.white,
                  indicatorColor: const Color(0xFFE0F2FF),
                  surfaceTintColor: Colors.white,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: _destinations,
                ),
              ),
    );
  }
}
