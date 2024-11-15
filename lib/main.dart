import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Importa latlong2
import 'package:geolocator/geolocator.dart'; // Importa geolocator
import 'package:acessibilidade_app/pages/avaliar_local_page.dart'; 

import 'package:acessibilidade_app/pages/mapa_locais.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Acessibilidade',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapaLocais(), // Define a tela inicial como o mapa de locais
    );
  }
}

