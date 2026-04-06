import 'dart:async';
import 'package:flutter/material.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/municipio.dart';
import 'package:momentofiscal/core/services/municipio/municipio_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';

class MunicipioSearchPage extends StatefulWidget {
  const MunicipioSearchPage({super.key});

  @override
  State<MunicipioSearchPage> createState() => _MunicipioSearchPageState();
}

class _MunicipioSearchPageState extends State<MunicipioSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final MunicipioService _municipioService = MunicipioService();
  List<Municipio> _municipios = [];
  Map<String, dynamic>? _dadosCompletos;
  Municipio? _municipioSelecionado;
  bool _isSearching = false;
  bool _isLoadingDetails = false;
  Timer? _debounce;

  String? _ufFiltro;

  static const List<String> _ufs = [
    'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
    'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.length >= 2) {
        _buscarMunicipios(value);
      } else {
        setState(() {
          _municipios = [];
        });
      }
    });
  }

  Future<void> _buscarMunicipios(String termo) async {
    setState(() => _isSearching = true);

    final result = await _municipioService.buscar(
      termo: termo,
      uf: _ufFiltro,
    );

    if (mounted) {
      setState(() {
        _municipios = result?.municipios ?? [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selecionarMunicipio(Municipio municipio) async {
    setState(() {
      _municipioSelecionado = municipio;
      _isLoadingDetails = true;
      _municipios = [];
      _searchController.text = municipio.nomeCompleto;
    });

    final dados = await _municipioService.consultarCompleto(
      codigoIbge: municipio.codigoIbge,
    );

    if (mounted) {
      setState(() {
        _dadosCompletos = dados;
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca por Município'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboadPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: Image.asset(
                  'assets/images/momentofiscalcolorido.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              _buildSearchCard(),
              const SizedBox(height: 10),
              if (_isSearching) const Center(child: CircularProgressIndicator()),
              if (_municipios.isNotEmpty) _buildResultsList(),
              if (_isLoadingDetails)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_dadosCompletos != null && !_isLoadingDetails)
                _buildDadosCompletos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card.outlined(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Busca por Município', style: textTitle),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      label: Text('Nome do município'),
                      hintText: 'Ex: São Paulo, Brasília...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _ufFiltro,
                    decoration: const InputDecoration(
                      label: Text('UF'),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._ufs.map((uf) =>
                          DropdownMenuItem(value: uf, child: Text(uf))),
                    ],
                    onChanged: (value) {
                      setState(() => _ufFiltro = value);
                      if (_searchController.text.length >= 2) {
                        _buscarMunicipios(_searchController.text);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Card.outlined(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _municipios.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = _municipios[index];
          return ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(m.nome),
            subtitle: Text('${m.uf} - IBGE: ${m.codigoIbge}'),
            trailing: m.populacao != null
                ? Text('Pop: ${_formatNumber(m.populacao!)}')
                : null,
            onTap: () => _selecionarMunicipio(m),
          );
        },
      ),
    );
  }

  Widget _buildDadosCompletos() {
    final dados = _dadosCompletos!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_municipioSelecionado != null)
          _buildMunicipioHeader(_municipioSelecionado!),
        if (dados['cauc'] != null) _buildSectionCard('CAUC', dados['cauc']),
        if (dados['pgfn'] != null) _buildSectionCard('PGFN', dados['pgfn']),
        if (dados['sancoes'] != null)
          _buildSancoesCard(dados['sancoes']),
        if (dados['siconfi'] != null)
          _buildSectionCard('SICONFI', dados['siconfi']),
        if (dados['transferencias'] != null)
          _buildSectionCard('Transferências Federais', dados['transferencias']),
        if (dados['fnde'] != null)
          _buildSectionCard('FNDE', dados['fnde']),
      ],
    );
  }

  Widget _buildMunicipioHeader(Municipio m) {
    return Card(
      elevation: 4,
      color: Theme.of(context).primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.location_city, color: Colors.white, size: 40),
        title: Text(
          m.nomeCompleto,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'IBGE: ${m.codigoIbge}${m.populacao != null ? ' | Pop: ${_formatNumber(m.populacao!)}' : ''}',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String titulo, dynamic dados) {
    return Card.outlined(
      child: ExpansionTile(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: const Icon(Icons.assessment),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _formatData(dados),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSancoesCard(Map<String, dynamic> sancoesData) {
    final total = sancoesData['total'] ?? 0;
    final sancoes = sancoesData['sancoes'] as List? ?? [];

    return Card.outlined(
      child: ExpansionTile(
        title: Text(
          'Sanções ($total)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: Icon(
          total > 0 ? Icons.warning_amber : Icons.check_circle,
          color: total > 0 ? Colors.orange : Colors.green,
        ),
        children: sancoes.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma sanção encontrada.'),
                ),
              ]
            : sancoes.map<Widget>((s) {
                return ListTile(
                  title: Text(s['tipo_cadastro'] ?? 'N/A'),
                  subtitle: Text(s['nome_orgao_sancionador'] ?? ''),
                  trailing: Text(s['data_inicio_sancao'] ?? ''),
                );
              }).toList(),
      ),
    );
  }

  String _formatData(dynamic data) {
    if (data is Map) {
      return data.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}: ${e.value}')
          .join('\n');
    }
    return data.toString();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }
}
