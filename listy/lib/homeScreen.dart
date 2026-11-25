import 'package:flutter/material.dart';

import '../banco/data_acess_object.dart';
import '../banco/model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Lista>> _listasFuture;

  @override
  void initState() {
    super.initState();
    _listasFuture = DataAccessObject.obterListas();
  }

  Future<void> _recarregarListas() async {
    final novaConsulta = DataAccessObject.obterListas();

    setState(() {
      _listasFuture = novaConsulta;
    });

    try {
      await novaConsulta;
    } catch (_) {
      // ERROR
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListY'),
      ),
      body: RefreshIndicator(
        onRefresh: _recarregarListas,
        child: FutureBuilder<List<Lista>>(
          future: _listasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Text('Não foi possível carregar as listas.'),
                    ),
                  ),
                ],
              );
            }

            final listas = snapshot.data ?? [];

            if (listas.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: Text('Você ainda não tem listas.')),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: listas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final lista = listas[index];
                final quantidadeChecados =
                    lista.items.where((item) => item.checado).length;
                final valorTotal = lista.items
                    .where((item) => item.checado)
                    .fold<double>(
                      0,
                      (total, item) => total + item.preco * item.quantidade,
                    );

                return ListTile(
                  title: Text(lista.nome),
                  subtitle: Text(
                    'Alterada em ${_formatarData(lista.modificado)}\n'
                    'Itens: $quantidadeChecados/${lista.items.length} checados'
                    ' • Total: ${_formatarMoeda(valorTotal)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Informações da lista',
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _mostrarInformacoes(
                      context,
                      lista: lista,
                      quantidadeChecados: quantidadeChecados,
                      valorTotal: valorTotal,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _mostrarInformacoes(
    BuildContext context, {
    required Lista lista,
    required int quantidadeChecados,
    required double valorTotal,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lista.nome),
        content: Text(
          'Última alteração: ${_formatarData(lista.modificado)}\n'
          'Itens checados: $quantidadeChecados/${lista.items.length}\n'
          'Valor dos itens checados: ${_formatarMoeda(valorTotal)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

String _formatarData(DateTime data) {
  final local = data.toLocal();

  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year} '
      '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}';
}

String _formatarMoeda(double valor) {
  final valorFormatado = valor.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $valorFormatado';
}