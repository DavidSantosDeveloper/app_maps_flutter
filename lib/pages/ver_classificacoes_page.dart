import 'package:flutter/material.dart';

class VerClassificacoesPage extends StatelessWidget {
  final String nomeLugar;
  final List<dynamic> comentarios; // Dados de comentários da API.
  final List<String> fotos; // URLs das fotos.

  VerClassificacoesPage({
    required this.nomeLugar,
    required this.comentarios,
    required this.fotos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nomeLugar),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context); // Fecha a tela.
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lista de Comentários
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Comentários",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: comentarios.length,
              itemBuilder: (context, index) {
                final comentario = comentarios[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comentario['nomePessoa'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            5,
                            (starIndex) => Icon(
                              Icons.star,
                              color: starIndex < comentario['estrelas']
                                  ? Colors.yellow
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(comentario['comentario']),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Seção de Fotos
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Fotos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: fotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      fotos[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
