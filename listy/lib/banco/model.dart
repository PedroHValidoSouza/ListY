import 'package:flutter/material.dart';

DateTime? parseNullDate(dynamic value) {
  if (value == null || (value is String && value.isEmpty)) return null;
  return DateTime.tryParse(value as String);
}

class Lista {
  final int? idLista; // Pode ser null antes de salvar (autoincrement)
  final String nome;
  final String icone;
  final Color cor;
  final DateTime criado;
  final DateTime modificado;
  final DateTime? concluida;
  final List<Item> items;

  Lista({
    this.idLista,
    required this.nome,
    required this.icone,
    required this.cor,
    required this.criado,
    required this.modificado,
    this.concluida,
    this.items = const [],
  });

  Lista patch({
    int? idLista,
    String? nome,
    String? icone,
    Color? cor,
    DateTime? criado,
    DateTime? modificado,
    DateTime? concluida,
    bool limparConcluida = false,
    List<Item>? items,
  }) {
    return Lista(
      idLista: idLista ?? this.idLista,
      nome: nome ?? this.nome,
      icone: icone ?? this.icone,
      cor: cor ?? this.cor,
      criado: criado ?? this.criado,
      modificado: modificado ?? this.modificado,
      concluida: limparConcluida ? null : (concluida ?? this.concluida),
      items: items ?? this.items,
    );
  }

  // Converte linha do SQLite -> Objeto Lista
  factory Lista.fromMap(Map<String, dynamic> map, {List<Item> items = const []}) {
    return Lista(
      idLista: map['id_lista'] as int?,
      nome: map['nome'] as String,
      icone: map['icone'] as String,
      cor: Color(map['cor'] as int),
      criado: DateTime.parse(map['criado'] as String),
      modificado: DateTime.parse(map['modificado'] as String),
      concluida: parseNullDate(map['concluida']),
      items: items,
    );
  }

  // Converte Objeto Lista -> Linha do SQLite (sem 'items', que vão para outra tabela)
  Map<String, dynamic> toMap() {
    return {
      if (idLista != null) 'id_lista': idLista,
      'nome': nome,
      'icone': icone,
      'cor': cor.toARGB32(),
      'criado': criado.toIso8601String(),
      'modificado': modificado.toIso8601String(),
      'concluida': concluida?.toIso8601String(),
    };
  }
}

class Item {
  final int? idItem;
  final int idLista; // Chave estrangeira ligando à Lista
  final bool checado;
  final DateTime? checadoEm;
  final String nome;
  final double preco;
  final int quantidade;
  final String detalhes;

  Item({
    this.idItem,
    required this.idLista,
    required this.checado,
    this.checadoEm,
    required this.nome,
    required this.preco,
    required this.quantidade,
    required this.detalhes,
  });

  Item patch({
    int? idItem,
    int? idLista,
    bool? checado,
    DateTime? checadoEm,
    bool limparChecadoEm = false,
    String? nome,
    double? preco,
    int? quantidade,
    String? detalhes,
  }) {
    return Item(
      idItem: idItem ?? this.idItem,
      idLista: idLista ?? this.idLista,
      checado: checado ?? this.checado,
      checadoEm: limparChecadoEm ? null : (checadoEm ?? this.checadoEm),
      nome: nome ?? this.nome,
      preco: preco ?? this.preco,
      quantidade: quantidade ?? this.quantidade,
      detalhes: detalhes ?? this.detalhes,
    );
  }

  // Converte linha do SQLite -> Objeto Item (0/1 vira bool)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      idItem: map['id_item'] as int?,
      idLista: map['id_lista'] as int,
      checado: (map['checado'] as int) == 1,
      checadoEm: parseNullDate(map['checado_em']),
      nome: map['nome'] as String,
      preco: (map['preco'] as num).toDouble(),
      quantidade: map['quantidade'] as int,
      detalhes: map['detalhes'] as String,
    );
  }

  // Converte Objeto Item -> Linha do SQLite (bool vira 0/1)
  Map<String, dynamic> toMap() {
    return {
      if (idItem != null) 'id_item': idItem,
      'id_lista': idLista,
      'checado': checado ? 1 : 0,
      'checado_em': checadoEm?.toIso8601String(),
      'nome': nome,
      'preco': preco,
      'quantidade': quantidade,
      'detalhes': detalhes,
    };
  }
}
