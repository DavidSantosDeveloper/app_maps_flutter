import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> avaliarLocal(String latitude,String longitude, String nota, String comentario) async {
    // Simula o envio da avaliação para o backend
    await Future.delayed(Duration(seconds: 1));
    print('Avaliação enviada: Local :=> latitude:$latitude longitude:$longitude, Nota: $nota, Comentário: $comentario');
  }
}
