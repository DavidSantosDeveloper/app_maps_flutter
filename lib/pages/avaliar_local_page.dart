import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Adicionando o pacote
import '../components/botao_acessivel.dart';
import '../servicos/local_service.dart';

class AvaliarLocalPage extends StatefulWidget {
  final String latitude;
  final String longitude;
  
  AvaliarLocalPage({Key? key, required this.latitude, required this.longitude}) : super(key: key);

  @override
  _AvaliarLocalPageState createState() => _AvaliarLocalPageState();
}

class _AvaliarLocalPageState extends State<AvaliarLocalPage> {
  TextEditingController comentarioController = TextEditingController();
  bool isLoading = false;
  double rating = 0.0;  // A variável para armazenar a nota selecionada

  // Função para validar a nota
  bool validarNota(double nota) {
    return nota >= 1 && nota <= 5;
  }

  // Função para enviar a avaliação
  Future<void> avaliarLocal(String latitude, String longitude, double nota, String comentario) async {
    final localService = LocalService();
    await localService.avaliarLocal(latitude, longitude, nota.toString(), comentario);
  }

  // Função para mostrar o dialog
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Avaliar Local"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Avalie este local:", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            // Seletor de estrelas usando o RatingBar
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 40,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (newRating) {
                setState(() {
                  rating = newRating;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: comentarioController,
              decoration: InputDecoration(
                labelText: "Comentário",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 20),
            BotaoAcessivel(
              onPress: () {
                enviarAvaliacao();
              },
              title: isLoading ? 'Enviando...' : 'Enviar Avaliação',
            ),
          ],
        ),
      ),
    );
  }

  // Função para enviar a avaliação
  Future<void> enviarAvaliacao() async {
    final comentario = comentarioController.text;

    if (!validarNota(rating)) {
      _showDialog('Erro', 'Por favor, selecione uma nota válida (1 a 5).');
      return;
    }

    if (comentario.trim().isEmpty) {
      _showDialog('Erro', 'Por favor, insira um comentário.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await avaliarLocal(widget.latitude, widget.longitude, rating, comentario);
      _showDialog('Sucesso', 'Avaliação enviada com sucesso!');
      Navigator.pop(context);
    } catch (error) {
      _showDialog('Erro', 'Ocorreu um erro ao enviar a avaliação. Tente novamente.');
      print('Erro ao enviar avaliação: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
