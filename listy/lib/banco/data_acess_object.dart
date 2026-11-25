import 'package:sqflite/sqflite.dart' as sql;
import 'model.dart';

class DataAccessObject {
  static const int _versaoBanco = 1;

  static Future<sql.Database> abrirBanco() async {
    return sql.openDatabase(
      'listadecompras.db',
      version: _versaoBanco,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE listas (
            id_lista INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            criado TEXT NOT NULL,
            modificado TEXT NOT NULL,
            concluida TEXT
          )
        ''');

        await database.execute('''
          CREATE TABLE lista_itens (
            id_item INTEGER PRIMARY KEY AUTOINCREMENT,
            id_lista INTEGER NOT NULL,
            checado INTEGER NOT NULL DEFAULT 0,
            checado_em TEXT,
            nome TEXT NOT NULL,
            preco REAL NOT NOT NULL,
            quantidade INTEGER NOT NULL,
            detalhes TEXT NOT NULL,
            FOREIGN KEY (id_lista)
              REFERENCES listas (id_lista)
              ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  static Future<int> incluirLista(Lista lista) async {
    final banco = await abrirBanco();

    return banco.transaction((transacao) async {
      final valoresLista = Map<String, dynamic>.from(lista.toMap())
        ..remove('id_lista');

      final idLista = await transacao.insert('listas', valoresLista);

      for (final item in lista.items) {
        final valoresItem = Map<String, dynamic>.from(item.toMap())
          ..remove('id_item')
          ..['id_lista'] = idLista;

        await transacao.insert('lista_itens', valoresItem);
      }

      return idLista;
    });
  }

  static Future<List<Lista>> obterListas() async {
    final banco = await abrirBanco();

    final mapasListas = await banco.query('listas', orderBy: 'nome');
    final mapasItens = await banco.query('lista_itens');

    final itensPorLista = <int, List<Item>>{};

    for (final mapa in mapasItens) {
      final item = Item.fromMap(Map<String, dynamic>.from(mapa));
      itensPorLista.putIfAbsent(item.idLista, () => []).add(item);
    }

    return mapasListas.map((mapa) {
      final dadosLista = Map<String, dynamic>.from(mapa);
      final idLista = dadosLista['id_lista'] as int;

      return Lista.fromMap(
        dadosLista,
        items: itensPorLista[idLista] ?? const [],
      );
    }).toList();
  }

  static Future<Lista?> obterLista(int idLista) async {
    final banco = await abrirBanco();

    final mapasLista = await banco.query(
      'listas',
      where: 'id_lista = ?',
      whereArgs: [idLista],
      limit: 1,
    );

    if (mapasLista.isEmpty) return null;

    final mapasItens = await banco.query(
      'lista_itens',
      where: 'id_lista = ?',
      whereArgs: [idLista],
      orderBy: 'nome',
    );

    final itens = mapasItens
        .map((mapa) => Item.fromMap(Map<String, dynamic>.from(mapa)))
        .toList();

    return Lista.fromMap(
      Map<String, dynamic>.from(mapasLista.first),
      items: itens,
    );
  }

  static Future<int> alterarLista(Lista lista) async {
    if (lista.idLista == null) {
      throw ArgumentError('A lista precisa ter idLista.');
    }

    final banco = await abrirBanco();
    final valores = Map<String, dynamic>.from(lista.toMap())
      ..remove('id_lista');

    return banco.update(
      'listas',
      valores,
      where: 'id_lista = ?',
      whereArgs: [lista.idLista],
    );
  }

  static Future<int> excluirLista(int idLista) async {
    final banco = await abrirBanco();

    return banco.delete(
      'listas',
      where: 'id_lista = ?',
      whereArgs: [idLista],
    );
  }

  static Future<int> incluirItem(Item item) async {
    final banco = await abrirBanco();
    final valores = Map<String, dynamic>.from(item.toMap())
      ..remove('id_item');

    return banco.insert('lista_itens', valores);
  }

  static Future<List<Item>> obterItens(int idLista) async {
    final banco = await abrirBanco();

    final mapas = await banco.query(
      'lista_itens',
      where: 'id_lista = ?',
      whereArgs: [idLista],
      orderBy: 'nome',
    );

    return mapas
        .map((mapa) => Item.fromMap(Map<String, dynamic>.from(mapa)))
        .toList();
  }

  static Future<int> alterarItem(Item item) async {
    if (item.idItem == null) {
      throw ArgumentError('O item precisa ter idItem.');
    }

    final banco = await abrirBanco();
    final valores = Map<String, dynamic>.from(item.toMap())
      ..remove('id_item');

    return banco.update(
      'lista_itens',
      valores,
      where: 'id_item = ?',
      whereArgs: [item.idItem],
    );
  }

  static Future<int> excluirItem(int idItem) async {
    final banco = await abrirBanco();

    return banco.delete(
      'lista_itens',
      where: 'id_item = ?',
      whereArgs: [idItem],
    );
  }
}