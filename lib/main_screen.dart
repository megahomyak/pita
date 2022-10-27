import 'package:dio_log/dio_log.dart';
import 'package:flutter/material.dart';
import 'package:pita/announcements.dart';
import 'package:pita/net_school_client.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.client});

  final NetSchoolClient client;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    showDebugBtn(context, btnColor: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: [AnnouncementsPage(client: widget.client)][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) => setState(() {
          _selectedIndex = index;
        }),
        items: const [
          BottomNavigationBarItem(
            label: 'Announcements',
            icon: Icon(Icons.announcement),
          ),
          BottomNavigationBarItem(
            label: 'Blah',
            icon: Icon(Icons.announcement),
          ),
        ],
      ),
    );
  }
}
