import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pita/business_page.dart';
import 'package:pita/home_page.dart';
import 'package:pita/school_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.client});

  final Dio client;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late final TabController tabController;

  @override
  void initState() {
    tabController = TabController(
      length: 3,
      initialIndex: 0,
      vsync: this,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Pita"),
          bottom: TabBar(
            controller: tabController,
            tabs: const [
              Tab(
                text: 'Home',
                icon: Icon(Icons.home),
              ),
              Tab(
                text: 'Business',
                icon: Icon(Icons.business),
              ),
              Tab(
                text: 'School',
                icon: Icon(Icons.school),
              )
            ],
          ),
        ),
        body: TabBarView(
          controller: tabController,
          children: [
            const HomePage(),
            const BusinessPage(),
            SchoolPage(
              client: widget.client,
            )
          ],
        ));
  }
}
