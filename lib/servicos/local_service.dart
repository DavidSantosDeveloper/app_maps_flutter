import 'package:http/http.dart' as http;
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

  
  
  
  Future<String> getLocationByCoordinates(double latitude, double longitude) async {
  final url = 'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    var data = json.decode(response.body);
    var address = data['address'];
    
    if (address != null) {
      // Abaixo você pode escolher os campos que quer, por exemplo, cidade, país, etc.
      String location = '${address['road']}, ${address['city']}, ${address['country']}';
      return location;
    } else {
      print ('Localização não encontrada.');
      return "";
    }
  } else {
    return "";
    throw Exception('Falha ao obter a localização');
  }
}


Future<int?> obterIdPrimeiroEnderecoPartindoDasCoordenadas(String latitude, String longitude) async {
  final url = 'http://192.168.1.110:8080/Local/coordenadas?latitude=$latitude&longitude=$longitude';

  try {
    // Fazendo a requisição GET
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // Decodificando a resposta JSON
      var dados = json.decode(response.body);

      // Verifica se os dados são uma lista e se não está vazia
      if (dados is List && dados.isNotEmpty) {
        // Obtém o primeiro elemento da lista
        var primeiroElemento = dados[0];

        // Retorna o atributo 'idDaLocalizacao', se ele existir
        if (primeiroElemento.containsKey('id')) {
          return primeiroElemento['id'];
        } else {
          return null; // Retorna null se o atributo 'idDaLocalizacao' não existir
        }
      } else {
        return null; // Retorna null se a lista estiver vazia ou não for uma lista
      }
    } else {
      return null; // Retorna null se a resposta da API não for bem-sucedida
    }
  } catch (e) {
    print('Erro: $e');
    return null; // Retorna null em caso de erro na requisição ou decodificação
  }
}








  Future<void> avaliarLocal(String latitude,String longitude, String nota, String comentario) async {
    // Simula o envio da avaliação para o backend
    // await Future.delayed(Duration(seconds: 1));
    // print('Avaliação enviada: Local :=> latitude:$latitude longitude:$longitude, Nota: $nota, Comentário: $comentario');



  final String url = '192.168.1.110:8080/Avaliacao'; // URL do seu endpoint


  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
 var data_atual=formatter.format(now);


  try {
    
    String location = await getLocationByCoordinates( double.parse(latitude) , double.parse(longitude) );
    print('Local: $location');
  } catch (e) {
    print('Erro: $e');
  }


    int? idDaLocalizacao = await obterIdPrimeiroEnderecoPartindoDasCoordenadas(latitude, longitude);

  if (idDaLocalizacao == null) {
    print('ID não encontrado ou ocorreu um erro na requisição.');
  } else {
    print('ID do primeiro elemento: $idDaLocalizacao');
  }


  // Cria o objeto de dados em formato JSON
  final Map<String, dynamic> dadosAvaliacao = {
    'estrelas': nota,
    'comentario': comentario,
    'dt_avaliacao':data_atual,
    'local':{
      'id':idDaLocalizacao ?? 0
    }
  };

  // Converte os dados para JSON
  final String jsonData = json.encode(dadosAvaliacao);

  // Faz a requisição POST
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json', // Define o tipo de conteúdo como JSON
      },
      body: jsonData,
    );

    if (response.statusCode == 200) {
      // Se a requisição for bem-sucedida
      print('Avaliação enviada com sucesso!');
    } else {
      // Caso o servidor retorne um erro
      print('Erro ao enviar avaliação: ${response.statusCode}');
    }
  } catch (error) {
    // Em caso de falha na requisição
    print('Erro ao fazer requisição: $error');
  }
  }

}
