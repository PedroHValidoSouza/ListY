import 'package:flutter/material.dart';
import 'package:listy/model.dart';

//Adicionar o DateFormater

class HomeScreen extends StatelessWidget {
const HomeScreen({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListY',
        style: TextStyle(
          fontWeight: FontWeight.bold
        ),),
      ),
      body: Container(
        color: Colors.black26,
        child: Padding(
          padding: const EdgeInsetsGeometry.all(8),
          child: ListView(
            children: [
              ListaTile(nome: "co", modificada: DateTime.now(), itensTotais: 6, itensChecados: 3, total: 200),
              ListaTile(nome: "co", modificada: DateTime.now(), itensTotais: 6, itensChecados: 3, total: 200),
              ListaTile(nome: "co", modificada: DateTime.now(), itensTotais: 6, itensChecados: 3, total: 200)
              ],
          ),
          ),
      ),
      floatingActionButton: 
        FloatingActionButton(
          onPressed: (){},
          child: Icon(Icons.list_alt_outlined),
          ),
    );
  }
}

class ListaTile extends StatelessWidget {
  final String nome;
  final DateTime modificada;
  final int itensTotais;
  final int itensChecados;
  final double total;

ListaTile({ 
  super.key,
  required this.nome,
  required this.modificada,
  required this.itensTotais,
  required this.itensChecados,
  required this.total, 
  });

  @override
  Widget build(BuildContext context){
    return ListTile(
      title: Text(nome),
      subtitle: Text("$itensChecados/$itensTotais, valor estimado em ${total.toStringAsFixed(2)}."),
      trailing: Icon(Icons.info),
    );
  }
}