import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';  // Para selecionar as imagens
import 'dart:io';  // Para lidar com arquivos de imagem
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
  List<XFile>? _imagensSelecionadas = [];  // Lista para armazenar as imagens selecionadas

   List lista_de_id_de_imagens_cadrastradas=[];
   int? id_avaliacao;

  // Função para validar a nota
  bool validarNota(double nota) {
    return nota >= 1 && nota <= 5;
  }

  // Função para enviar a avaliação
  Future<int?> avaliarLocal(String latitude, String longitude, double nota, String comentario) async {
    final localService = LocalService();
    int? id_do_local_cadrastrado=await localService.avaliarLocal(latitude, longitude, nota.toString(), comentario);

    if(id_do_local_cadrastrado==null){
        return null;
        print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ID DO LOCAL NULL<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
    }

    

    this.id_avaliacao=id_do_local_cadrastrado;


    print("id do objeto avaliar local foi atualizado!${id_do_local_cadrastrado}");
    return id_avaliacao;
  }


  Future<List?> enviarFotoSeparada(List<XFile>? imagens) async {
  if (imagens == null || imagens.isEmpty) {
    print('Nenhuma imagem para enviar.');
    return null;
  }

    final localService = LocalService();
    List lista_de_id_de_imagens_cadrastradas=await localService.uploadImagem(imagens); 
    this.lista_de_id_de_imagens_cadrastradas=lista_de_id_de_imagens_cadrastradas;
    return lista_de_id_de_imagens_cadrastradas;

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

  // Função para escolher imagens da galeria
  Future<void> _selecionarImagens() async {
    final picker = ImagePicker();
    final List<XFile>? imagens = await picker.pickMultiImage();
    if (imagens != null && imagens.isNotEmpty) {
      setState(() {
        _imagensSelecionadas = imagens;
      });
    }
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
            // Botão para escolher imagens
            ElevatedButton(
              onPressed: _selecionarImagens,
              child: Text('Escolher Imagens'),
            ),
            SizedBox(height: 10),
            // Exibir imagens selecionadas
            _imagensSelecionadas!.isEmpty
                ? Text("Nenhuma imagem selecionada.")
                : Text("${_imagensSelecionadas!.length} imagem(s) selecionada(s)."),
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

  // Função para enviar a avaliação e a foto
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
      // Envia a foto para o endpoint /Fotos/upload
      await enviarFotoSeparada(_imagensSelecionadas);

      // Envia a avaliação
      await avaliarLocal(widget.latitude, widget.longitude, rating, comentario);

      LocalService local=new LocalService();
      await local.relacionarFotoComAvaliacao(this.id_avaliacao,this.lista_de_id_de_imagens_cadrastradas);

      

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
