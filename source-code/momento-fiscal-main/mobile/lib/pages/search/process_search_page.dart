import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/process_jusbrasil_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/search/debtors_nearby.dart';

class ProcessSearchPage extends StatefulWidget {
  final String? cpfCnpj;

  const ProcessSearchPage({this.cpfCnpj, super.key});

  @override
  State<ProcessSearchPage> createState() => _ProcessSearchPageState();
}

class _ProcessSearchPageState extends State<ProcessSearchPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController processController = TextEditingController();
  List<Jusbrasil> jusbrasilList = [];
  bool isSearchingStream = false;
  bool searchDone = false;
  StreamSubscription<List<Jusbrasil>>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    final initial = widget.cpfCnpj ?? '';
    if (initial.isNotEmpty) {
      processController.text = CpfCnpjInputFormatter.format(initial);
      WidgetsBinding.instance.addPostFrameCallback((_) => _searchByCpfCnpj());
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    processController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  Future<void> _searchByCpfCnpj() async {
    _streamSubscription?.cancel();
    setState(() {
      isSearchingStream = true;
      searchDone = false;
      jusbrasilList = [];
    });

    try {
      final stream = ProcessJusbrasil().getProcessesCpfCnpjStream(
        cpfCnpj: processController.text,
      );

      _streamSubscription = stream.listen(
        (fetchedList) {
          if (mounted) {
            setState(() {
              jusbrasilList = fetchedList;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              isSearchingStream = false;
              searchDone = true;
            });
          }
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              isSearchingStream = false;
              searchDone = true;
            });
            final msg = e.toString().replaceFirst('Exception: ', '');
            _showError(
              msg.isNotEmpty ? msg : 'Erro ao buscar processos. Por favor, tente novamente.',
            );
          }
        },
      );
    } catch (e) {
      setState(() {
        isSearchingStream = false;
        searchDone = true;
      });
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showError(
        msg.isNotEmpty ? msg : 'Erro ao buscar processos. Por favor, tente novamente.',
      );
    }
  }

  List<Content> get _allContent =>
      jusbrasilList.expand<Content>((j) => j.content ?? <Content>[]).toList();

  String _formatProcessNumber(String number) {
    if (number.length != 20) return number;
    return '${number.substring(0, 7)}-${number.substring(7, 9)}.${number.substring(9, 13)}.${number.substring(13, 14)}.${number.substring(14, 16)}.${number.substring(16, 20)}';
  }

  String _getSigiloLabel(int nivel) {
    switch (nivel) {
      case 0:
        return 'Público';
      case 1:
        return 'Segredo de Justiça (Nível 1)';
      case 2:
        return 'Segredo de Justiça (Nível 2)';
      case 3:
        return 'Segredo de Justiça (Nível 3)';
      case 4:
        return 'Segredo de Justiça (Nível 4)';
      case 5:
        return 'Segredo de Justiça (Nível 5)';
      default:
        return 'Nível $nivel';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allContent = _allContent;
    final hasResults = allContent.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca de Processos por CPF/CNPJ'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _streamSubscription?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboadPage(),
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                  if (isSearchingStream || searchDone)
                    _buildMotorDeBusca(allContent),
                  if (hasResults) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${allContent.length} processo(s) encontrado(s)',
                          style: textTitle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildResultsSection(allContent),
                  ],
                  if (searchDone && !hasResults)
                    _buildEmptyState(),
                ],
              ),
            ),
          ),
          if (!isSearchingStream && !searchDone)
            const DebtorsNearby(),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card.outlined(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Consultar Processos Judiciais', style: textTitle),
                const SizedBox(height: 6),
                const Text(
                  'Digite o CPF ou CNPJ para buscar processos em todos os tribunais',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    key: const ValueKey('cpfCnpj'),
                    controller: processController,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      label: Text('CPF ou CNPJ'),
                      hintText: 'Digite o CPF ou CNPJ',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    inputFormatters: [CpfCnpjInputFormatter()],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o CPF ou CNPJ';
                      }
                      if (value.length == 14) {
                        return validatorCpf(value);
                      } else if (value.length == 18) {
                        return validatorCnpj(value);
                      }
                      return 'CPF ou CNPJ inválido';
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Theme.of(context).primaryColor,
                    fixedSize: const Size.fromWidth(500),
                  ),
                  onPressed: isSearchingStream
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          if (_formKey.currentState?.validate() ?? false) {
                            _searchByCpfCnpj();
                          }
                        },
                  child: const Text(
                    'Buscar Processos',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Motor de busca visual
  // ---------------------------------------------------------------------------

  Widget _buildMotorDeBusca(List<Content> allContent) {
    final groups = [
      _TribunalGroup(
        label: 'TJs Estaduais',
        icon: Icons.account_balance,
        count: allContent.where((c) => c.siglaTribunal.startsWith('TJ')).length,
      ),
      _TribunalGroup(
        label: 'TRFs (Federais)',
        icon: Icons.gavel,
        count: allContent.where((c) => c.siglaTribunal.startsWith('TRF')).length,
      ),
      _TribunalGroup(
        label: 'TRT (Trabalho)',
        icon: Icons.work,
        count: allContent.where((c) => c.siglaTribunal.startsWith('TRT')).length,
      ),
      _TribunalGroup(
        label: 'STJ',
        icon: Icons.star_border,
        count: allContent.where((c) => c.siglaTribunal == 'STJ').length,
      ),
      _TribunalGroup(
        label: 'STF',
        icon: Icons.star,
        count: allContent.where((c) => c.siglaTribunal == 'STF').length,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isSearchingStream) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Motor de busca — consultando tribunais...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Lista consolidada de processos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              ...groups.map((g) => _buildGroupRow(g)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupRow(_TribunalGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Linha de árvore
          const SizedBox(width: 8),
          const Text('├── ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Icon(group.icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              group.label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (group.count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${group.count}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            )
          else
            isSearchingStream
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : const Text(
                    'Nenhum',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seção de resultados
  // ---------------------------------------------------------------------------

  Widget _buildResultsSection(List<Content> allContent) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allContent.length,
      itemBuilder: (context, index) => _buildProcessCard(allContent[index]),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(20.0),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhum processo encontrado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Não foram encontrados processos vinculados a este CPF/CNPJ',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessCard(Content processo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(
          processo.nivelSigilo == 0 ? Icons.public : Icons.lock,
          color: processo.nivelSigilo == 0 ? Colors.green : Colors.orange,
        ),
        title: Text(
          _formatProcessNumber(processo.numeroProcesso),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Tribunal: ${processo.siglaTribunal}'),
            Text(_getSigiloLabel(processo.nivelSigilo)),
          ],
        ),
        children: [
          if (processo.tramitacoes.isNotEmpty)
            ...processo.tramitacoes.map(
              (tramitacao) => _buildTramitacaoDetails(tramitacao),
            ),
        ],
      ),
    );
  }

  Widget _buildTramitacaoDetails(Tramitacao tramitacao) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Tribunal', tramitacao.tribunal.sigla),
          _buildInfoRow('Grau', tramitacao.grau.nome),
          if (tramitacao.classe.isNotEmpty)
            _buildInfoRow('Classe', tramitacao.classe[0].descricao),
          if (tramitacao.dataHoraUltimaDistribuicao != null)
            _buildInfoRow(
              'Data Distribuição',
              _formatDate(tramitacao.dataHoraUltimaDistribuicao!),
            ),
          if (tramitacao.valorAcao > 0)
            _buildInfoRow(
              'Valor da Ação',
              'R\$ ${tramitacao.valorAcao.toStringAsFixed(2)}',
            ),
          if (tramitacao.orgaoJulgador != null)
            _buildInfoRow('Órgão Julgador', tramitacao.orgaoJulgador!.nome),
          if (tramitacao.assunto != null && tramitacao.assunto!.isNotEmpty)
            _buildAssuntosSection(tramitacao.assunto!),
          if (tramitacao.partes.isNotEmpty)
            _buildPartesSection(tramitacao.partes),
          if (tramitacao.ultimoMovimento != null)
            _buildUltimoMovimento(tramitacao.ultimoMovimento!),
          _buildInfoRow('Status', tramitacao.ativo ? 'Ativo' : 'Inativo'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssuntosSection(List<Assunto> assuntos) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assuntos:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          ...assuntos.map(
            (assunto) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                '• ${assunto.descricao ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartesSection(List<Parte> partes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partes:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          ...partes.map(
            (parte) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${parte.polo}: ${parte.nome}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (parte.representantes != null &&
                      parte.representantes!.isNotEmpty)
                    ...parte.representantes!.map(
                      (rep) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Text(
                          '${rep.tipoRepresentacao}: ${rep.nome}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimoMovimento(UltimoMovimento movimento) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Último Movimento:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código: ${movimento.codigo}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(movimento.dataHora),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// ---------------------------------------------------------------------------
// Helper data class para o motor de busca
// ---------------------------------------------------------------------------

class _TribunalGroup {
  final String label;
  final IconData icon;
  final int count;

  const _TribunalGroup({
    required this.label,
    required this.icon,
    required this.count,
  });
}

// ---------------------------------------------------------------------------
// Formatter automático CPF / CNPJ
// ---------------------------------------------------------------------------

class CpfCnpjInputFormatter extends TextInputFormatter {
  static String format(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digits.length > 14 ? digits.substring(0, 14) : digits;
    return _buildFormatted(limited);
  }

  static String _buildFormatted(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    if (digits.length <= 11) {
      // CPF: 000.000.000-00
      for (int i = 0; i < digits.length; i++) {
        if (i == 3 || i == 6) buf.write('.');
        if (i == 9) buf.write('-');
        buf.write(digits[i]);
      }
    } else {
      // CNPJ: 00.000.000/0000-00
      for (int i = 0; i < digits.length; i++) {
        if (i == 2) buf.write('.');
        if (i == 5) buf.write('.');
        if (i == 8) buf.write('/');
        if (i == 12) buf.write('-');
        buf.write(digits[i]);
      }
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digits.length > 14 ? digits.substring(0, 14) : digits;
    final formatted = _buildFormatted(limited);

    // Encontra a posição do cursor contando dígitos antes do cursor no texto cru
    final cursorIndex = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = newValue.text
        .substring(0, cursorIndex)
        .replaceAll(RegExp(r'[^\d]'), '')
        .length;
    final clampedDigits = digitsBeforeCursor.clamp(0, limited.length);

    // Mapeia para a posição equivalente no texto formatado
    int cursor = 0;
    if (clampedDigits > 0) {
      int count = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (RegExp(r'\d').hasMatch(formatted[i])) {
          count++;
          if (count == clampedDigits) {
            cursor = i + 1;
            break;
          }
        }
      }
      if (cursor == 0) cursor = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
