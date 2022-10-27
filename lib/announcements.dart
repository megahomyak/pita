import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pita/models.dart';
import 'package:pita/net_school_client.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({Key? key, required this.client}) : super(key: key);

  final NetSchoolClient client;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: FutureBuilder(
            future: client.getAnnouncements(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
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
                        Text(announcement.content),
                        const Divider(
                          thickness: 2,
                        ),
                      ]);
                    })
                  ],
                );
              }
              if (snapshot.hasError) {
                log("An announcement could not be loaded!", error: snapshot.error, name: "pita.error");
                return const Text("An error occured!");
              }
              return const Text('No Data');
            }));
  }
}
