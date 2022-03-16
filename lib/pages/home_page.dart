import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  // ignore: prefer_const_constructors
  LatLng? _position;
  final String _marked = '1';

  _moveCamera() async {
    //método para mover a câmera quando. Está chamando esse método no floatingActionButton
    GoogleMapController _googleMapController = await _controller.future;

    _googleMapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              _position!, //posição que a câmera vai ficar quando chamar o método.
          //Nesse caso vai sempre pra posição que ficou marcada no mapa
          bearing: 90, //inclinação da câmera (em graus)
          tilt: 90, //rotacionar a câmera (em graus)
          zoom: 16,
        ),
      ),
    );
  }
  
  _getUserLocation() {
    Geolocator()
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa e geolocalização'),
        centerTitle: true,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-23.547374, -46.641267),
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
        onLongPress: (LatLng position) {
          //está mudando o local marcado no mapa
          setState(() {
            _position = position;
          });
        },
        markers: {
          //local onde ficará marcado o mapa
          Marker(
            markerId: MarkerId(_marked),
            position: _position != null
                ? _position!
                : const LatLng(0,
                    0), //fiz essa condição pra quando iniciar o mapa, não estar já com um local marcado
            infoWindow: const InfoWindow(
                snippet: 'Subtitle da marcação',
                title: 'Título que aparecerá na marcação'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure, //cor do ícone de marcação
            ),
            // ignore: avoid_print
            onTap: () => print('Clicou no marcador'),
            // rotation: 45,
          ),
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.location_on),
        onPressed: () {
          _moveCamera();
        },
      ),
    );
  }
}
