import 'package:flutter/material.dart';

import '../banco/model.dart';

class ListaDetalhesPage extends StatelessWidget {
  final Lista lista;

  const ListaDetalhesPage({
    super.key,
    required this.lista,
  });

  @override
  Widget build(BuildContext context) {
    final itensChecados = lista.items.where((item) => item.checado).length;

    final valorTodosItens = lista.items.fold<double>(
      0,
      (total, item) => total + item.preco * item.quantidade,
    );

    final valorItensChecados = lista.items
        .where((item) => item.checado)
        .fold<double>(
          0,
          (total, item) => total + item.preco * item.quantidade,
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da lista'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _cartaoInformacoesLista(
            itensChecados: itensChecados,
            valorTodosItens: valorTodosItens,
            valorItensChecados: valorItensChecados,
          ),
          const SizedBox(height: 24),
          Text(
            'Itens (${lista.items.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (lista.items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Esta lista ainda não tem itens.'),
              ),
            )
          else
            ...lista.items.map(_cartaoItem),
        ],
      ),
    );
  }

  Widget _cartaoInformacoesLista({
    required int itensChecados,
    required double valorTodosItens,
    required double valorItensChecados,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lista.nome,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _linhaInformacao('ID da lista', _exibirId(lista.idLista)),
            _linhaInformacao('Criada em', _formatarData(lista.criado)),
            _linhaInformacao(
              'Última alteração',
              _formatarData(lista.modificado),
            ),
            _linhaInformacao(
              'Concluída em',
              lista.concluida == null
                  ? 'Ainda não concluída'
                  : _formatarData(lista.concluida!),
            ),
            const Divider(height: 24),
            _linhaInformacao(
              'Itens checados',
              '$itensChecados/${lista.items.length}',
            ),
            _linhaInformacao(
              'Valor de todos os itens',
              _formatarMoeda(valorTodosItens),
            ),
            _linhaInformacao(
              'Valor dos itens checados',
              _formatarMoeda(valorItensChecados),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoItem(Item item) {
    final subtotal = item.preco * item.quantidade;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.checado
                      ? Icons.check_box
                      : Icons.square_outlined,
                  
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(item.checado ? 'Checado' : 'Pendente'),
              ],
            ),
            const Divider(height: 24),
            _linhaInformacao('ID do item', _exibirId(item.idItem)),
            _linhaInformacao('ID da lista', item.idLista.toString()),
            _linhaInformacao(
              'Checado em',
              item.checadoEm == null
                  ? 'Não checado'
                  : _formatarData(item.checadoEm!),
            ),
            _linhaInformacao('Quantidade', item.quantidade.toString()),
            _linhaInformacao('Preço unitário', _formatarMoeda(item.preco)),
            _linhaInformacao('Subtotal', _formatarMoeda(subtotal)),
            _linhaInformacao(
              'Detalhes',
              item.detalhes.trim().isEmpty ? 'Sem detalhes' : item.detalhes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaInformacao(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              rotulo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(valor)),
        ],
      ),
    );
  }
}

String _exibirId(int? id) => id?.toString() ?? 'Ainda não salvo';

String _formatarData(DateTime data) {
  final local = data.toLocal();

  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year} '
      '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}';
}

String _formatarMoeda(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}