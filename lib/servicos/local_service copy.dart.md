import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class LocalService {
  Future<List<dynamic>> buscarLocais(String tipoAcessibilidade) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/locais'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Erro ao carregar locais.');
      }
    } catch (e) {
      throw Exception('Erro ao carregar locais. Tente novamente.');
    }
  }

  Future<String> getLocationByCoordinates(
      double latitude, double longitude) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var address = data['address'];

      if (address != null) {
        String? houseNumber = address['house_number'];

        String? city = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['hamlet'] ??
            address['suburb'];

        String road = address['road'] ?? 'Endereço não especificado';
        String country = address['country'] ?? 'País não especificado';

        String formattedAddress =
            '$road,${houseNumber != null ? '$houseNumber ' : 'número não encontrado '}, ${city ?? 'Localidade não especificada'}, $country';

        return formattedAddress;
      } else {
        print('Localização não encontrada.');
        return "Localização não encontrada.";
      }
    } else {
      return 'Falha ao obter a localização';
    }
  }

  Future<int?> obterIdPrimeiroEnderecoPartindoDasCoordenadas(
      String latitude, String longitude) async {
    final url =
        'https://back-end-app-maps-acessibilidade.onrender.com/Local/coordenadas?latitude=$latitude&longitude=$longitude';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var dados = json.decode(response.body);

        if (dados is List && dados.isNotEmpty) {
          var primeiroElemento = dados[0];
          print(primeiroElemento);

          if (primeiroElemento.containsKey('id')) {
            return primeiroElemento['id'];
          } else {
            return null;
          }
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      print('Erro: $e');
      return null;
    }
  }

  Future<int?> cadastrarLocal(
      String localizacao, double latitude, double longitude) async {
    final String url =
        'https://backendappmapsacessibilidade-production.up.railway.app/Local';

    final Map<String, dynamic> dadosLocal = {
      'localizacao': localizacao,
      'latitude': latitude,
      'longitude': longitude,
    };

    final String jsonData = json.encode(dadosLocal);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );

      if (response.statusCode == 201) {
        print('Localização enviada com sucesso!');
        var dadosRetorno = json.decode(response.body);

        if (dadosRetorno is Map<String, dynamic>) {
          var idRetornado = dadosRetorno['id'];
          print('ID cadastrado: $idRetornado');
          return idRetornado;
        } else {
          print('Resposta inesperada: $dadosRetorno');
        }
      } else {
        print('Erro ao enviar localização: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro ao fazer requisição: $error');
    }

    return null;
  }

  Future<void> avaliarLocal(
      String latitude, String longitude, String nota, String comentario) async {
    final String url =
        'https://backendappmapsacessibilidade-production.up.railway.app/Avaliacao';

    var now = DateTime.now();
    var formatter = DateFormat('yyyy-MM-dd');
    var dataAtual = formatter.format(now);

    String location = "";
    try {
      location = await getLocationByCoordinates(
          double.parse(latitude), double.parse(longitude));
      print('Local: $location');
    } catch (e) {
      print('Erro: $e');
    }

    int? idDaLocalizacao =
        await obterIdPrimeiroEnderecoPartindoDasCoordenadas(latitude, longitude);

    if (idDaLocalizacao == null) {
      print('ID do local não encontrado no banco de dados!');
      idDaLocalizacao = await cadastrarLocal(
          location, double.parse(latitude), double.parse(longitude));
    } else {
      print('ID do LOcal do primeiro elemento encontrado no Banco de dados: $idDaLocalizacao');
    }

    // final Map<String, dynamic> dadosAvaliacao = {
    //   'estrelas': nota,
    //   'comentario': comentario,
    //   'dt_avaliacao': dataAtual,
    //   'local': {
    //     'id': idDaLocalizacao,
    //   },
    // };
    final Map<String, dynamic> dadosAvaliacao = {
      'estrelas': nota,
      'comentario': comentario,
      'dt_avaliacao': dataAtual,
      'local': {
        'id': idDaLocalizacao,
      },
    };
    
    print(dadosAvaliacao);

    final String jsonData = json.encode(dadosAvaliacao);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );

      if (response.statusCode == 201) {
        print('Avaliação enviada com sucesso!');
      } else {
        print('Erro ao enviar avaliação: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro ao fazer requisição: $error');
    }
  }



Future<void> uploadImagem(XFile imagem) async {
  final uri = Uri.parse('https://backendappmapsacessibilidade-production.up.railway.app/Foto/upload');
  final request = http.MultipartRequest('POST', uri);

  // Adiciona a imagem como multipart usando XFile
  request.files.add(
    await http.MultipartFile.fromPath(
      'file', // Nome do campo esperado pelo servidor
      imagem.path,
    ),
  );

  try {
    final response = await request.send();
    if (response.statusCode == 201) {
      print('Upload bem-sucedido');
    } else {
      print('Falha no upload. Código de status: ${response.statusCode}');
    }
  } catch (error) {
    print('Erro durante o upload: $error');
  }
}

 

}
