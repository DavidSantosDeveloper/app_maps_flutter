import 'package:flutter/material.dart';
import '../components/botao_acessivel.dart';
import '../servicos/local_service.dart';




class AvaliarLocalPage extends StatefulWidget {

  final String latitude;
  final String longitude;
AvaliarLocalPage({Key? key, required String latitude, required String longitude})
      : latitude = latitude,
        longitude = longitude,
        super(key: key) {
    // Bloco de inicialização para realizar ações adicionais
    latitude=this.latitude;
    longitude=this.longitude;

  }
  @override
  _AvaliarLocalPageState createState() => _AvaliarLocalPageState();
}

class _AvaliarLocalPageState extends State<AvaliarLocalPage> {
  TextEditingController notaController = TextEditingController();
  TextEditingController comentarioController = TextEditingController();
  bool isLoading = false;

  // Função para validar a nota
  bool validarNota(String nota) {
    final notaInt = int.tryParse(nota);
    return notaInt != null && notaInt >= 1 && notaInt <= 5;
  }

  // Função para enviar a avaliação
  Future<void> avaliarLocal(String latitude,String longitude, String nota, String comentario) async {
    // Aqui, você pode chamar o método do serviço ou implementar o envio da avaliação diretamente.
    final localService = LocalService(); // Certifique-se de que o LocalService está importado
    await localService.avaliarLocal(widget.latitude,widget.longitude, nota, comentario);
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
            TextField(
              controller: notaController,
              decoration: InputDecoration(
                labelText: "Nota (1-5)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
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
    final nota = notaController.text;
    final comentario = comentarioController.text;

    if (nota.isEmpty || !validarNota(nota)) {
      _showDialog('Erro', 'Por favor, insira uma nota válida (1 a 5).');
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
      
      await avaliarLocal(widget.latitude,widget.longitude, nota, comentario); // Chama o método de avaliação
      _showDialog('Sucesso', 'Avaliação enviada com sucesso!');
      Navigator.pop(context); // Volta para a tela anterior
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
