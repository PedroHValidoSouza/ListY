import 'package:flutter/material.dart';

import '../banco/data_acess_object.dart';
import '../banco/model.dart';
import './detalhesScreen.dart';
import 'listaScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Lista>> _listasFuture;

  int? _listaEmEdicaoId;
  final TextEditingController _nomeListaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _listasFuture = _listasExemplo();
   // DataAccessObject.obterListas();
  }

  @override
  void dispose() {
    _nomeListaController.dispose();
    super.dispose();
  }

  Future<void> _recarregarListas() async {
    final consulta = DataAccessObject.obterListas();

    setState(() {
      _listasFuture = consulta;
    });

    try {
      await consulta;
    } catch (_) {
      // O FutureBuilder apresenta o estado de erro.
    }
  }

  Future<void> _adicionarLista() async {
    final agora = DateTime.now();
    final dia = agora.day.toString().padLeft(2, '0');
    final mes = agora.month.toString().padLeft(2, '0');
    final nomeInicial = 'Lista nova $dia/$mes';

    final novaLista = Lista(
      nome: nomeInicial,
      criado: agora,
      modificado: agora,
      items: const [],
    );

    try {
      final idLista = await DataAccessObject.incluirLista(novaLista);

      if (!mounted) return;

      _nomeListaController.text = nomeInicial;
      setState(() {
        _listaEmEdicaoId = idLista;
      });

      await _recarregarListas();
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar a lista: $erro')),
      );
    }
  }

  void _iniciarEdicaoNome(Lista lista) {
    final id = lista.idLista;
    if (id == null) return;

    _nomeListaController.text = lista.nome;

    setState(() {
      _listaEmEdicaoId = id;
    });
  }

  Future<void> _salvarNomeLista(Lista lista) async {
    final novoNome = _nomeListaController.text.trim();

    if (novoNome.isEmpty || lista.idLista == null) {
      setState(() {
        _listaEmEdicaoId = null;
      });
      return;
    }

    try {
      final listaAtualizada = lista.patch(
        nome: novoNome,
        modificado: DateTime.now(),
      );

      await DataAccessObject.alterarLista(listaAtualizada);

      if (!mounted) return;

      setState(() {
        _listaEmEdicaoId = null;
      });

      await _recarregarListas();
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o nome: $erro')),
      );
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
                    child: Center(
                      child: Text('Você ainda não tem listas.'),
                    ),
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
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _iniciarEdicaoNome(lista),
                        child: Text(lista.nome),
                      ),
                      if (_listaEmEdicaoId == lista.idLista)
                        TextField(
                          controller: _nomeListaController,
                          autofocus: true,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            hintText: 'Digite o nome da lista',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _salvarNomeLista(lista),
                        ),
                    ],
                  ),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              ListaDetalhesPage(lista: lista),
                        ),
                      );
                    },
                  ),
                  onTap: () {
  final idLista = lista.idLista;

  if (idLista == null) return;

  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ListaPage(idLista: idLista),
    ),
  );
},
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarLista,
        tooltip: 'Adicionar lista',
        child: const Icon(Icons.post_add),
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
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

Future<List<Lista>> _listasExemplo() async {
  final agora = DateTime.now();

  final listaMercado = Lista(
    idLista: 1,
    nome: 'Compras do mercado',
    criado: agora.subtract(const Duration(days: 5)),
    modificado: agora.subtract(const Duration(hours: 2)),
    concluida: null,
    items: [
      Item(
        idItem: 1,
        idLista: 1,
        checado: true,
        checadoEm: agora.subtract(const Duration(hours: 2)),
        nome: 'Arroz',
        preco: 24.90,
        quantidade: 2,
        detalhes: 'Pacote de 5 kg',
      ),
      Item(
        idItem: 2,
        idLista: 1,
        checado: true,
        checadoEm: agora.subtract(const Duration(hours: 1)),
        nome: 'Feijão',
        preco: 8.50,
        quantidade: 3,
        detalhes: 'Tipo carioca',
      ),
      Item(
        idItem: 3,
        idLista: 1,
        checado: false,
        checadoEm: null,
        nome: 'Leite',
        preco: 5.20,
        quantidade: 6,
        detalhes: 'Integral',
      ),
    ],
  );

  final listaFarmacia = Lista(
    idLista: 2,
    nome: 'Farmácia',
    criado: agora.subtract(const Duration(days: 2)),
    modificado: agora.subtract(const Duration(minutes: 20)),
    concluida: agora.subtract(const Duration(minutes: 20)),
    items: [
      Item(
        idItem: 4,
        idLista: 2,
        checado: true,
        checadoEm: agora.subtract(const Duration(minutes: 20)),
        nome: 'Paracetamol',
        preco: 12.75,
        quantidade: 1,
        detalhes: 'Caixa com 20 comprimidos',
      ),
    ],
  );

  // Simula o tempo de uma consulta ao banco.
  await Future<void>.delayed(const Duration(milliseconds: 600));

  return [listaMercado, listaFarmacia];
}