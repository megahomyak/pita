import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Announcement {
  final String description;
  final String name;

  Announcement({required this.description, required this.name});

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      description: json['description'],
      name: json['name'],
    );
  }
}

class SchoolPage extends StatelessWidget {
  const SchoolPage({Key? key, required this.client}) : super(key: key);

  final Dio client;

  Future<List<Announcement>> getAnnouncements() async {
    final Response response = await client.get('/announcements?take=-1');
    log(response.toString());
    final List<dynamic> announcementMap = response.data as List<dynamic>;
    final List<Announcement> announcements = announcementMap
        .map((announcement) =>
            Announcement.fromJson(announcement as Map<String, dynamic>))
        .toList();
    return announcements;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getAnnouncements(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: const CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            final List<Announcement> announcementsList = snapshot.data;
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(
                  height: 10,
                ),
                const Text('Announcements'),
                const SizedBox(
                  height: 10,
                ),
                ...announcementsList.map((announcement) {
                  return Column(children: [
                    Text(announcement.description),
                    const Divider(
                      thickness: 2,
                    ),
                  ]);
                })
              ],
            );
          }
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          return const Text('No Data');
        });
  }
}
