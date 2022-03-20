import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_and_geolocations/pages/map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StreamController<QuerySnapshot<Map<String, dynamic>>>
      _streamController = StreamController();

  _loadPlaces() {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var stream = firestore.collection('places').snapshots();

    stream.listen((data) {
      _streamController.add(data);
    });
  }

  _deleteLocation(String id) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('places').doc(id).delete();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _loadPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const Text(''),
          centerTitle: true,
          title: const Text('Minhas localizações'),
        ),
        body: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _streamController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.active) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  List<DocumentSnapshot> listItems =
                      snapshot.data!.docs.toList();

                  return Expanded(
                    child: ListView.builder(
                        itemCount: listItems.length,
                        itemBuilder: (context, index) {
                          var id = listItems[index].id;
                          return Card(
                            elevation: 5,
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: ((context) => MapPage(
                                          latLgn: LatLng(
                                              listItems[index]['latitude'],
                                              listItems[index]['longitude']),
                                        )),
                                  ),
                                );
                              },
                              title:
                                  Text(listItems[index]['streetInformations']),
                              subtitle:
                                  Text(listItems[index]['localeInformations']),
                              trailing: IconButton(
                                onPressed: () {
                                  _deleteLocation(id);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          );
                        }),
                  );
                }
              },
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/mapPage');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
