import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/services/processDataCrawlers/process_number_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/search/debtors_nearby.dart';

class ProcessSearchPage extends StatefulWidget {
  final String? numeroProcesso;

  const ProcessSearchPage({this.numeroProcesso, super.key});

  @override
  State<ProcessSearchPage> createState() => _ProcessSearchPageState();
}

class _ProcessSearchPageState extends State<ProcessSearchPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController processController = TextEditingController();
  List<Content>? processResults;
  bool isLoading = false;
  late MaskedInputFormatter _processFormatter;

  @override
  void initState() {
    super.initState();
    processController.text = widget.numeroProcesso ?? "";
    _processFormatter = MaskedInputFormatter('0000000-00.0000.0.00.0000');
    _verifyProcessIsEmpty();
  }

  @override
  void dispose() {
    processController.dispose();
    super.dispose();
  }

  Future _verifyProcessIsEmpty() async {
    if (processController.text.isNotEmpty) {
      setState(() {
        _fetchProcessData();
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  Future<void> _fetchProcessData() async {
    setState(() {
      isLoading = true;
      processResults = null;
    });

    try {
      // Remove máscara e espaços
      final cleanedNumber = processController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanedNumber.length != 20) {
        _showError('Número do processo deve ter 20 dígitos');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await ProcessNumberService()
          .getProcessByNumber(numeroProcesso: cleanedNumber);

      setState(() {
        if (response != null && response.content != null && response.content!.isNotEmpty) {
          processResults = response.content;
        } else {
          processResults = [];
        }
      });
    } catch (e) {
      _showError(
        'Erro ao buscar processo. Por favor, tente novamente em alguns minutos.'
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatProcessNumber(String number) {
    if (number.length != 20) return number;
    // Formato: NNNNNNN-DD.AAAA.J.TR.OOOO
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Busca por Número de Processo'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  _buildSearchCard(),
                  const SizedBox(height: 10),
                  if (processResults != null && processResults!.isNotEmpty)
                    const Text('Informações do Processo', style: textTitle),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!isLoading) _buildResultsSection(),
                ],
              ),
            ),
          ),
          if (!isLoading && processResults == null)
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
                const Text('Consultar Processo Judicial', style: textTitle),
                const SizedBox(height: 10),
                const Text(
                  'Digite o número do processo no formato CNJ (20 dígitos)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    key: const ValueKey('numeroProcesso'),
                    controller: processController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      label: Text('Número do Processo'),
                      hintText: '0000000-00.0000.0.00.0000',
                      helperText: 'Ex: 0000001-23.2024.8.07.0001',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    inputFormatters: [_processFormatter],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o número do processo';
                      }
                      final cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (cleanedValue.length != 20) {
                        return 'Número do processo deve ter 20 dígitos';
                      }
                      return null;
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
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState?.validate() ?? false) {
                      _fetchProcessData();
                    }
                  },
                  child: const Text('Buscar Processo',
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (processResults != null && processResults!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Processo não encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Verifique se o número foi digitado corretamente',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (processResults != null && processResults!.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: processResults!.length,
        itemBuilder: (context, index) {
          final processo = processResults![index];
          return _buildProcessCard(processo);
        },
      );
    }

    return const SizedBox.shrink();
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
            ...processo.tramitacoes.map((tramitacao) => 
              _buildTramitacaoDetails(tramitacao)
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
            _buildInfoRow('Data Distribuição', 
              _formatDate(tramitacao.dataHoraUltimaDistribuicao!)),
          if (tramitacao.valorAcao > 0)
            _buildInfoRow('Valor da Ação', 
              'R\$ ${tramitacao.valorAcao.toStringAsFixed(2)}'),
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
          ...assuntos.map((assunto) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 2),
            child: Text('• ${assunto.descricao ?? ''}', style: const TextStyle(fontSize: 12)),
          )),
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
          ...partes.map((parte) => Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${parte.polo}: ${parte.nome}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                if (parte.representantes != null && parte.representantes!.isNotEmpty)
                  ...parte.representantes!.map((rep) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Text(
                      '${rep.tipoRepresentacao}: ${rep.nome}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  )),
              ],
            ),
          )),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
