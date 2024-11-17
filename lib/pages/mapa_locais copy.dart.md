import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:acessibilidade_app/pages/avaliar_local_page.dart';

class MapaLocais extends StatefulWidget {
  @override
  _MapaLocaisState createState() => _MapaLocaisState();
}

class _MapaLocaisState extends State<MapaLocais> {
  final MapController _mapController = MapController();
  double? latitude;
  double? longitude;
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> searchResults = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Função para solicitar permissão de localização
  Future<void> _getCurrentLocation() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      try {
        // Obtém a localização do usuário
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          isLoading = false;
        });
        // Move o mapa para a localização atual
        _mapController.move(LatLng(latitude!, longitude!), 15.0);
      } catch (e) {
        setState(() {
          error = 'Erro ao obter localização: $e';
          isLoading = false;
        });
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      // Caso a permissão seja negada, solicita novamente ou abre as configurações
      _showLocationPermissionDialog(context);
    } else {
      // Caso a permissão não seja concedida
      setState(() {
        error = 'Permissão de localização não concedida';
        isLoading = false;
      });
    }
  }

  // Função para mostrar um alerta para pedir permissão
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de Locais'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar Local',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                if (query.isNotEmpty) {
                  _searchLocation(query);
                } else {
                  setState(() {
                    searchResults = [];
                  });
                }
              },
            ),
          ),
          if (searchResults.isNotEmpty)
            Container(
              height: 150,
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final location = searchResults[index];
                  return ListTile(
                    title: Text(location["display_name"] ?? "Local desconhecido"),
                    onTap: () {
                      double lat = double.tryParse(location["lat"]) ?? 0.0;
                      double lon = double.tryParse(location["lon"]) ?? 0.0;
                      _moveToLocation(lat, lon);
                    },
                  );
                },
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
                      initialCenter: latitude != null && longitude != null
                          ? LatLng(latitude!, longitude!)
                          : LatLng(-23.5505, -46.6333), // Localização padrão
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _navigateToAvaliarLocalPage,
              child: Text("Avaliar Local"),
            ),
          ),
        ],
      ),
    );
  }

  // Atualiza a latitude e longitude e move o mapa
  void _moveToLocation(double lat, double lon) {
    setState(() {
      latitude = lat;
      longitude = lon;
    });
    _mapController.move(LatLng(lat, lon), 15.0);
  }

  // Função para buscar locais via API
  Future<void> _searchLocation(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        searchResults = List<Map<String, dynamic>>.from(data);
      });
    } else {
      setState(() {
        error = 'Erro ao buscar locais';
      });
    }
  }

  // Função para obter a localização com base nas coordenadas
  Future<String> getLocationByCoordinates(double latitude, double longitude) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var address = data['address'];

      if (address != null) {
        // Tenta obter o número da casa
        String? houseNumber = address['house_number'];

        // Tenta obter a cidade de diferentes campos
        String? city = address['city'] ?? 
            address['town'] ?? 
            address['village'] ?? 
            address['hamlet'] ?? 
            address['suburb'];

        // Monta a string de localização
        String road = address['road'] ?? 'Endereço não especificado';
        String country = address['country'] ?? 'País não especificado';

        // Formata o endereço com o número da casa, se existir
        String formattedAddress = '$road,${houseNumber != null ? '$houseNumber ' : 'número não encontrado '}, ${city ?? 'Localidade não especificada'}, $country';

        return formattedAddress;
      } else {
        print('Localização não encontrada.');
        return "Localização não encontrada.";
      }
    } else {
      return 'Falha ao obter a localização';
    }
  }

  // Função de navegação para a página de avaliação
  void _navigateToAvaliarLocalPage() {
    if (latitude != null && longitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AvaliarLocalPage(latitude: latitude.toString(), longitude: longitude.toString()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Coordenadas não disponíveis")),
      );
    }
  }
}
