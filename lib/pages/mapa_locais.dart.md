import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Importa latlong2
import 'package:geolocator/geolocator.dart'; // Importa geolocator
import 'package:permission_handler/permission_handler.dart'; 

class MapaLocais extends StatefulWidget {
  @override
  _MapaLocaisState createState() => _MapaLocaisState();
}

class _MapaLocaisState extends State<MapaLocais> {
  final MapController _mapController = MapController();
  double? latitude;
  double? longitude;
  bool isLoading = true; // Ajustando o estado inicial para exibir o carregamento
  String? error;



  // Função para exibir o diálogo solicitando permissão de localização
void _showLocationPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Permissão de Localização'),
        content: Text('Este aplicativo precisa da sua permissão para acessar sua localização.'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              // Abre as configurações de permissão no dispositivo
              openAppSettings();
              Navigator.of(context).pop();
            },
            child: Text('Abrir Configurações'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancelar'),
          ),
        ],
      );
    },
  );
}

  // Função para obter a localização atual
  Future<void> _getCurrentLocation() async {
     PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          isLoading = false;
        });
        // Mover o mapa para a nova posição
        _mapController.move(LatLng(latitude!, longitude!), 15.0);
      } catch (e) {
        setState(() {
          error = 'Erro ao obter localização: $e';
          isLoading = false;
        });
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      // Solicita permissão se o usuário não concedeu
      _showLocationPermissionDialog(context);
    }


    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        isLoading = false; // Quando a localização for obtida, o carregamento é finalizado
      });
      // Mover o mapa para a nova posição
      _mapController.move(LatLng(latitude!, longitude!), 15.0);
    } catch (e) {
      setState(() {
        error = 'Erro ao obter localização: $e';
        isLoading = false; // Em caso de erro, também finaliza o carregamento
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtém a localização atual ao iniciar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Locais'),
      ),
      body: Column(
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => _getCurrentLocation(),
                  child: const Text('Atualizar Localização'),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      minZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: ['a', 'b', 'c'],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
