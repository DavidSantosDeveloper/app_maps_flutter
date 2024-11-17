import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
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

  Future<int> avaliarLocal(
      String latitude, String longitude, String nota, String comentario) async {
    final String url =
        'https://backendappmapsacessibilidade-production.up.railway.app/Avaliacao';

        var idRetornado;

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
        var dadosRetorno = json.decode(response.body);

        if (dadosRetorno is Map<String, dynamic>) {
          idRetornado = dadosRetorno['id'];
          print('ID da avaliacao cadastrado: $idRetornado');
          
        }

      } else {
        print('Erro ao enviar avaliação: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro ao fazer requisição: $error');
    }



       return  Future.value(idRetornado)  ;
  
  }



Future< List<dynamic>> uploadImagem(List<XFile>? imagens) async {

    List lista_de_id_imagens_cadrastradas=[];

    if (imagens == null || imagens.isEmpty) {
      print('Nenhuma imagem selecionada para upload.');
      return lista_de_id_imagens_cadrastradas;
    }

    final uri = Uri.parse(
        'https://backendappmapsacessibilidade-production.up.railway.app/Foto/upload');
    final request = http.MultipartRequest('POST', uri);

    // Adiciona todas as imagens ao request
    for (var imagem in imagens) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // Nome do campo esperado pelo servidor
          imagem.path,
        ),
      );
    }

    try {
      final response = await request.send();

       // Converte o resultado em texto
     final responseBody = await http.Response.fromStream(response);
     final List<dynamic> jsonData = jsonDecode(responseBody.body);

      if (response.statusCode == 201) {
        print('Upload bem-sucedido de todas as imagens.');
        print('Resposta do servidor: ${responseBody.body}');
        for (var imageResponse in jsonData) {
             print('Imagem registrada com ID: ${imageResponse['id']}');
             lista_de_id_imagens_cadrastradas.add(imageResponse['id']);

             print(imageResponse);
        }
      } else {
        print('Falha no upload. Código de status: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro durante o upload: $error');

      
    }

    return lista_de_id_imagens_cadrastradas;

  }

  Future<void> relacionarFotoComAvaliacao(int? id_avaliacao,List lista_de_id_de_imagens_cadrastradas) async{
            final String url =
        'https://backendappmapsacessibilidade-production.up.railway.app/itemFoto';


   


    for(var id_foto in lista_de_id_de_imagens_cadrastradas){
           Map<String, dynamic> dadosItemFoto = {
                'avaliacao': {
                  'id': id_avaliacao,
                },
                'foto': {
                  'id': id_foto,
                }
            };
            final String jsonData = json.encode(dadosItemFoto);



            try {
                final response = await http.post(
                  Uri.parse(url),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                  body: jsonData,
                );

                if (response.statusCode == 201) {
                  print('Relacao Avaliacao e foto feita com  com sucesso!');
                  var dadosRetorno = json.decode(response.body);

                  if (dadosRetorno is Map<String, dynamic>) {
                    print('objeto ItemFoto do resposta do server: $dadosRetorno');
                    
                  } else {
                    print('Resposta inesperada: $dadosRetorno');
                  }
                  } else {
                    print('Erro ao enviar ItemFoto : ${response.statusCode}');
                  }
                } catch (error) {
                  print('Erro ao fazer requisição: $error');
                }


    }


    




  }

 

}
