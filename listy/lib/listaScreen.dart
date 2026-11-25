import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../banco/data_acess_object.dart';
import './banco/model.dart';

enum _FiltroItens { todos, checados, faltando }

class ListaPage extends StatefulWidget {
  final int idLista;

  const ListaPage({
    super.key,
    required this.idLista,
  });

  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  Lista? _lista;
  bool _carregando = true;
  String? _erro;
  _FiltroItens _filtro = _FiltroItens.todos;

  @override
  void initState() {
    super.initState();
    _carregarLista();
  }

  Future<void> _carregarLista() async {
    try {
      final lista = await DataAccessObject.obterLista(widget.idLista);

      if (!mounted) return;

      setState(() {
        _lista = lista;
        _erro = lista == null ? 'Lista não encontrada.' : null;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar a lista: $erro';
        _carregando = false;
      });
    }
  }

  Future<void> _atualizarDataModificacao() async {
    final lista = _lista;
    if (lista?.idLista == null) return;

    final listaAtualizada = lista!.patch(modificado: DateTime.now());
    await DataAccessObject.alterarLista(listaAtualizada);
  }

  Future<void> _salvarItem(Item item) async {
    try {
      await DataAccessObject.alterarItem(item);
      await _atualizarDataModificacao();
      await _carregarLista();
    } catch (erro) {
      _mostrarMensagem('Não foi possível salvar o item: $erro');
    }
  }

  Future<void> _alternarItem(Item item, bool checado) async {
    final itemAtualizado = item.patch(
      checado: checado,
      checadoEm: checado ? DateTime.now() : null,
      limparChecadoEm: !checado,
    );

    await _salvarItem(itemAtualizado);
  }

  Future<void> _alterarQuantidade(Item item, int variacao) async {
    final novaQuantidade = item.quantidade + variacao;

    // A quantidade nunca pode ficar abaixo de 1.
    if (novaQuantidade < 1) return;

    await _salvarItem(item.patch(quantidade: novaQuantidade));
  }

  Future<void> _adicionarItem() async {
    final lista = _lista;
    if (lista?.idLista == null) return;

    final novoItem = Item(
      idLista: lista!.idLista!,
      checado: false,
      nome: 'Produto...',
      preco: 0.0,
      quantidade: 1,
      detalhes: '',
    );

    try {
      await DataAccessObject.incluirItem(novoItem);
      await _atualizarDataModificacao();
      await _carregarLista();
    } catch (erro) {
      _mostrarMensagem('Não foi possível adicionar o item: $erro');
    }
  }

  Future<void> _editarItem(Item item) async {
    final itemEditado = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditorItemSheet(item: item),
    );

    // Se o modal foi cancelado, não grava nada.
    if (itemEditado == null) return;

    await _salvarItem(itemEditado);
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_erro != null || _lista == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lista')),
        body: Center(child: Text(_erro ?? 'Lista não encontrada.')),
      );
    }

    final lista = _lista!;
    final itensFiltrados = lista.items.where((item) {
      switch (_filtro) {
        case _FiltroItens.todos:
          return true;
        case _FiltroItens.checados:
          return item.checado;
        case _FiltroItens.faltando:
          return !item.checado;
      }
    }).toList();

    final itensChecados = lista.items.where((item) => item.checado).length;
    final valorComprado = lista.items
        .where((item) => item.checado)
        .fold<double>(
          0,
          (total, item) => total + item.preco * item.quantidade,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(lista.nome),
      ),
      body: RefreshIndicator(
        onRefresh: _carregarLista,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _CabecalhoLista(
              lista: lista,
              itensChecados: itensChecados,
              valorComprado: valorComprado,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  _botaoFiltro('Todos', _FiltroItens.todos),
                  _botaoFiltro('Checados', _FiltroItens.checados),
                  _botaoFiltro('Faltando', _FiltroItens.faltando),
                ],
              ),
            ),
            if (itensFiltrados.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    lista.items.isEmpty
                        ? 'Esta lista ainda não tem itens.'
                        : 'Não há itens nesta categoria.',
                  ),
                ),
              )
            else
              ...itensFiltrados.map(_construirItem),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: _adicionarItem,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar item'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoFiltro(String texto, _FiltroItens filtro) {
    return ChoiceChip(
      label: Text(texto),
      selected: _filtro == filtro,
      onSelected: (_) {
        setState(() {
          _filtro = filtro;
        });
      },
    );
  }

  Widget _construirItem(Item item) {
    final subtotal = item.preco * item.quantidade;

    return ListTile(
      leading: Checkbox(
        value: item.checado,
        onChanged: (valor) {
          if (valor != null) {
            _alternarItem(item, valor);
          }
        },
      ),
      title: Text(
        item.nome,
        style: TextStyle(
          decoration: item.checado ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_formatarMoeda(item.preco)} × ${item.quantidade}'
            ' = ${_formatarMoeda(subtotal)}',
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Diminuir quantidade',
                visualDensity: VisualDensity.compact,
                onPressed: item.quantidade > 1
                    ? () => _alterarQuantidade(item, -1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${item.quantidade}'),
              IconButton(
                tooltip: 'Aumentar quantidade',
                visualDensity: VisualDensity.compact,
                onPressed: () => _alterarQuantidade(item, 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _editarItem(item),
    );
  }
}

class _CabecalhoLista extends StatelessWidget {
  final Lista lista;
  final int itensChecados;
  final double valorComprado;

  const _CabecalhoLista({
    required this.lista,
    required this.itensChecados,
    required this.valorComprado,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lista.nome,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Total dos itens comprados: ${_formatarMoeda(valorComprado)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('Itens checados: $itensChecados/${lista.items.length}'),
            const SizedBox(height: 4),
            Text('Última alteração: ${_formatarData(lista.modificado)}'),
          ],
        ),
      ),
    );
  }
}

class _EditorItemSheet extends StatefulWidget {
  final Item item;

  const _EditorItemSheet({required this.item});

  @override
  State<_EditorItemSheet> createState() => _EditorItemSheetState();
}

class _EditorItemSheetState extends State<_EditorItemSheet> {
  late final TextEditingController _nomeController;
  late final TextEditingController _precoController;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _detalhesController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item.nome);
    _precoController = TextEditingController(
      text: widget.item.preco.toString(),
    );
    _quantidadeController = TextEditingController(
      text: widget.item.quantidade.toString(),
    );
    _detalhesController = TextEditingController(text: widget.item.detalhes);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _precoController.dispose();
    _quantidadeController.dispose();
    _detalhesController.dispose();
    super.dispose();
  }

  double get _precoDigitado {
    final texto = _precoController.text.trim().replaceAll(',', '.');
    return double.tryParse(texto) ?? 0;
  }

  int get _quantidadeDigitada {
    return int.tryParse(_quantidadeController.text.trim()) ?? 1;
  }

  void _salvar() {
    final nome = _nomeController.text.trim();
    final preco = _precoDigitado;
    final quantidade = _quantidadeDigitada;

    if (nome.isEmpty) {
      _mostrarErro('Informe o nome do produto.');
      return;
    }

    if (preco < 0) {
      _mostrarErro('O preço não pode ser negativo.');
      return;
    }

    if (quantidade < 1) {
      _mostrarErro('A quantidade deve ser pelo menos 1.');
      return;
    }

    Navigator.of(context).pop(
      widget.item.patch(
        nome: nome,
        preco: preco,
        quantidade: quantidade,
        detalhes: _detalhesController.text.trim(),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _precoDigitado * _quantidadeDigitada;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Editar item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _campo(
              titulo: 'Nome do produto',
              controller: _nomeController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    titulo: 'Preço',
                    controller: _precoController,
                    teclado: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    formatadores: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9,.]'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    titulo: 'Quantidade',
                    controller: _quantidadeController,
                    teclado: TextInputType.number,
                    formatadores: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _campo(
              titulo: 'Detalhes',
              controller: _detalhesController,
              maxLinhas: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text('Subtotal: ${_formatarMoeda(subtotal)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  // Fecha sem retornar alterações: o rascunho é descartado.
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _salvar,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo({
    required String titulo,
    required TextEditingController controller,
    TextInputType? teclado,
    List<TextInputFormatter>? formatadores,
    int maxLinhas = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: teclado,
          inputFormatters: formatadores,
          maxLines: maxLinhas,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

String _formatarMoeda(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

String _formatarData(DateTime data) {
  final local = data.toLocal();

  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  return '${doisDigitos(local.day)}/${doisDigitos(local.month)}/${local.year} '
      '${doisDigitos(local.hour)}:${doisDigitos(local.minute)}';
}