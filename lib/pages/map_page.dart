///Possui 2 métodos para pegar a localização atual do usuário
///1º: Pega através de um stream, portanto vai atualizando a localização do usuário de tempo em tempo
///2º: Pega a localização quando o método é chamado

//pra funcionar precisa instalar duas dependências:
//1: google_maps_flutter
//2: permission_handler
///o google_maps_flutter não possui opção pra solicitar acesso à localização
////novamente caso o usuário negue o acesso. Por isso adicionei essa outra
///dependência pra conseguir solicitar novamente

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  final LatLng? latLgn;
  const MapPage({
    Key? key,
    this.latLgn,
  }) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

LatLng? _userPosition;
double _latitude = 0.0;
double _longitude = 0.0;

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  Set<Marker> markers = {};
  bool isMarked = false;

  Future _addMarkerAndSaveOnFirebase(LatLng latLng) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    _latitude = latLng.latitude;
    _longitude = latLng.longitude;

    List<Placemark> placemarks =
        await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    var placeMarkItem = placemarks[0];

    String streetInformations =
        '${placeMarkItem.street}, ${placeMarkItem.subThoroughfare}';

    String localeInformations =
        '${placeMarkItem.subAdministrativeArea}, ${placeMarkItem.administrativeArea}, ${placeMarkItem.isoCountryCode}';

    await firestore.collection('places').add({
      'latitude': latLng.latitude,
      'longitude': latLng.longitude,
      'streetInformations': streetInformations,
      'localeInformations': localeInformations,
    });

    setState(() {
      if (isMarked == false) {
        markers.add(
          Marker(
            markerId: const MarkerId('userPosition'),
            position: LatLng(
                latLng.latitude,
                latLng
                    .longitude), //fiz essa condição pra quando iniciar o mapa, não estar já com um local marcado
            infoWindow: const InfoWindow(
                snippet: 'Última localização carregada pelo APP',
                title: 'Sua última localização'),
            // icon: BitmapDescriptor.defaultMarkerWithHue(
            //   BitmapDescriptor.hueAzure, //cor do ícone de marcação
            // ),
            // ignore: avoid_print
            onTap: () =>
                print('Clicou no marcador da última localização carregada'),
            rotation: 45,
          ),
        );
      }
    });

    _moveCamera(latLng: latLng);
    isMarked = true;
  }

  Future<bool> _validatePermissionToLocation() async {
    //pra conseguir validar se o usuário permitiu que o APP tenha acesso à localização,
    //precisa instalar a dependência "permission_handler" e usar conforme nessa função

    bool isGranted = await Permission.location.isGranted;
    //verifica se o usuário permitiu o acesso à localização

    if (!isGranted) {
      if (widget.latLgn != null) await Permission.location.request();
      //pede novamente o acesso à localização
    }

    return isGranted;
  }

  _moveCamera({required LatLng latLng}) async {
    //método para mover a câmera. Está chamando esse método no floatingActionButton
    GoogleMapController _googleMapController = await _controller.future;

    _googleMapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target:
              latLng, //posição que a câmera vai ficar quando chamar o método.
          //Nesse caso vai sempre pra localização atual do usuário
          bearing: 0, //inclinação da câmera (em graus)
          tilt: 0, //rotacionar a câmera (em graus)
          zoom: 16,
        ),
      ),
    );
  }

  // _getUserLocation() async {
  //   //pega a localização atual do usuário e adiciona um marcador pra essa localização

  //   bool havePermission = await _validatePermissionToLocation();
  //   if (!havePermission) {
  //     return;
  //   }

  //   Position currentPosition = await Geolocator.getCurrentPosition();

  //   _userPosition = LatLng(
  //     currentPosition.latitude,
  //     currentPosition.longitude,
  //   );

  //   Marker _userMarker = Marker(
  //     markerId: const MarkerId('userPosition'),
  //     position: _userPosition != null
  //         ? _userPosition!
  //         : const LatLng(0,
  //             0), //fiz essa condição pra quando iniciar o mapa, não estar já com um local marcado
  //     infoWindow: const InfoWindow(
  //         snippet: 'Última localização carregada pelo APP',
  //         title: 'Sua última localização'),
  //     // icon: BitmapDescriptor.defaultMarkerWithHue(
  //     //   BitmapDescriptor.hueAzure, //cor do ícone de marcação
  //     // ),
  //     // ignore: avoid_print
  //     onTap: () => print('Clicou no marcador da última localização carregada'),
  //     rotation: 45,
  //   );

  //   setState(() {
  //     markers.add(_userMarker);
  //   });
  // }

  Future<void> _getUserLocationStream() async {
    //pega a localização do usuário a partir de um stream.
    //Atualiza de tempo em tempo a localização
    bool havePermission = await _validatePermissionToLocation();
    if (!havePermission) {
      return;
    }

    Geolocator.getPositionStream(
      distanceFilter:
          10, //distância que o usuário precisa se mover pra receber uma
      //notificação. O ideal é colocar algum valor, pois de padrão o valor
      //é 0 e com isso vai atualizar muito, fazendo com que gaste muitos
      //recursos do celular (bateria, internet, etc)
      intervalDuration: const Duration(
          seconds:
              5), //de quanto em quanto tempo vai atualizar a localização. No IOS esse valor é ignorado
      desiredAccuracy: LocationAccuracy
          .high, //Acesse a classe LocationAccuracy pra ver a precisão
    ).listen((position) {
      _userPosition = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  void didChangeDependencies() {
    if (widget.latLgn != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('userPosition'),
          position: widget.latLgn!,
          infoWindow: const InfoWindow(
            title: 'Localização marcada',
            snippet: 'Local de marcação',
          ),
          // icon: BitmapDescriptor.defaultMarkerWithHue(
          //   BitmapDescriptor.hueAzure, //cor do ícone de marcação
          // ),
          // ignore: avoid_print
          onTap: () =>
              print('Clicou no marcador da última localização carregada'),
          rotation: 45,
        ),
      );

      _moveCamera(latLng: widget.latLgn!);
    }
    super.didChangeDependencies();
    _getUserLocationStream();
  }

  @override
  Widget build(BuildContext context) {
    // LatLng latLngMarked = ModalRoute.of(context)!.settings.arguments as LatLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa e geolocalização'),
        centerTitle: true,
      ),
      body: GoogleMap(
        myLocationEnabled: true, //mostra a localização do usuário
        mapType: MapType.normal,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-23.547374, -46.641267),
          zoom: 8,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
        onLongPress: (LatLng position) {
          if (isMarked == false && widget.latLgn == null) {
            _addMarkerAndSaveOnFirebase(
              LatLng(
                position.latitude,
                position.longitude,
              ),
            );
          }
        },
        markers: markers,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'null',
            child: const Icon(Icons.location_searching_outlined),
            onPressed: () {
              _moveCamera(latLng: _userPosition!);
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            child: const Icon(Icons.location_on),
            onPressed: widget.latLgn != null
                ? () {
                    _moveCamera(latLng: widget.latLgn!);
                  }
                : () {
                    _moveCamera(latLng: LatLng(_latitude, _longitude));
                  },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
