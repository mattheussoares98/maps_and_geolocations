import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// ignore: prefer_const_constructors

LatLng _position = const LatLng(0, 0);

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? _userPosition;
  Set<Marker> markers = {};

  _moveCamera({required bool isUserPosition}) async {
    bool isGranted = await Permission.location.isGranted;

    if (!isGranted) {
      await Permission.location.request();
    }

    //método para mover a câmera. Está chamando esse método no floatingActionButton
    GoogleMapController _googleMapController = await _controller.future;

    await _getUserLocation();
    //só chama esse método pra pegar a localização atual, caso o usuário tenha
    //permitido o acesso à localização do dispositivo

    if (isUserPosition) {
      //se não houver marcação, não executa
      _googleMapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                _userPosition!, //posição que a câmera vai ficar quando chamar o método.
            //Nesse caso vai sempre pra posição que ficou marcada no mapa
            bearing: 90, //inclinação da câmera (em graus)
            tilt: 90, //rotacionar a câmera (em graus)
            zoom: 16,
          ),
        ),
      );
    } else if (_position != const LatLng(0, 0)) {
      _googleMapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                _position, //posição que a câmera vai ficar quando chamar o método.
            //Nesse caso vai sempre pra posição que ficou marcada no mapa
            bearing: 90, //inclinação da câmera (em graus)
            tilt: 90, //rotacionar a câmera (em graus)
            zoom: 16,
          ),
        ),
      );
    }
  }

  _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition();

    double latitude = position.latitude;
    double longitude = position.longitude;

    _userPosition = LatLng(latitude, longitude);

    Marker _userMarker = Marker(
      markerId: const MarkerId('userPosition'),
      position: _userPosition != null
          ? _userPosition!
          : const LatLng(0,
              0), //fiz essa condição pra quando iniciar o mapa, não estar já com um local marcado
      infoWindow: const InfoWindow(
          snippet: 'Última localização carregada pelo APP',
          title: 'Sua última localização'),
      // icon: BitmapDescriptor.defaultMarkerWithHue(
      //   BitmapDescriptor.hueAzure, //cor do ícone de marcação
      // ),
      // ignore: avoid_print
      onTap: () => print('Clicou no marcador da última localização carregada'),
      rotation: 45,
    );
    setState(() {
      markers.add(_userMarker);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getUserLocation();
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
          print('longPress');
          setState(() {
            _position = position;
          });

          markers.add(
            Marker(
              markerId: const MarkerId('markedPosition'),
              position:
                  _position, //fiz essa condição pra quando iniciar o mapa, não estar já com um local marcado
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
          );
        },
        markers: markers,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.location_searching_outlined),
            onPressed: () {
              _moveCamera(isUserPosition: true);
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            child: const Icon(Icons.location_on),
            onPressed: () {
              _moveCamera(isUserPosition: false);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
