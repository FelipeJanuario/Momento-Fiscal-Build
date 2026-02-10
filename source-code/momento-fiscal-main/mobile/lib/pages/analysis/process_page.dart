import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:momentofiscal/core/models/company.dart';
import 'package:momentofiscal/core/models/jusbrasil.dart';
import 'package:momentofiscal/core/models/debt.dart';

class ProcessPage extends StatelessWidget {
  final List<dynamic> listProcess;
  final Company? company;
  final List<Debt>? listDebts;
  final String tribunal;
  final num countProcess;
  const ProcessPage({
    super.key,
    required this.listProcess,
    this.company,
    this.listDebts,
    required this.tribunal,
    required this.countProcess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processos'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Center(
                child: SizedBox(
                  height: 100,
                  child: Image.asset('assets/images/momentofiscalcolorido.png',
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 15),
              if (company != null) ...[
                Text(
                  company?.fantasyName ??
                      company?.corporateName ??
                      "NOME NÃO REGISTRADO",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  company?.cnpj ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ] else if (listDebts != null) ...[
                Text(
                  listDebts?.first?.debtedName ?? "NOME NÃO REGISTRADO",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  listDebts?.first?.cpfCnpj ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              Text(tribunal),
              Text('Quantidade de Processos: $countProcess'),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listProcess.length,
                itemBuilder: (context, index) {
                  Content process = listProcess[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        key: const Key('cardList'),
                        elevation: 3,
                        color: Colors.white,
                        child: ListTile(
                          title: Row(
                            children: [
                              Text('N°: ${process.numeroProcesso}'),
                              IconButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                            text: process.numeroProcesso))
                                        .then((_) {
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Número copiado!'),
                                        ),
                                      );
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Color.fromARGB(255, 115, 181, 184),
                                    size: 20,
                                  ))
                            ],
                          ),
                          titleTextStyle: const TextStyle(
                            color: Color.fromARGB(255, 115, 181, 184),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ...process.tramitacoes.map(
                                (tramitacao) => Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(
                                        'Ajuízamento: ${tramitacao.dataHoraUltimaDistribuicao != null ? DateFormat("dd/MM/yyyy").format(DateTime.parse(tramitacao.dataHoraUltimaDistribuicao.toString())) : 'Não exibida'}'),
                                    const SizedBox(height: 3),
                                    Text(
                                        'Último Movimento: ${DateFormat("dd/MM/yyyy").format(DateTime.parse(tramitacao.ultimoMovimento!.dataHora))}'),
                                    const SizedBox(height: 3),
                                    ...tramitacao.classe.map(
                                      (classe) => Column(
                                        children: [
                                          Text(
                                              'Classe: ${classe.descricao}(${classe.codigo})'),
                                          const SizedBox(height: 3),
                                        ],
                                      ),
                                    ),
                                    ...tramitacao.assunto!.map(
                                      (assunto) => Column(
                                        children: [
                                          Text(
                                              'Assunto: ${assunto.hierarquia ?? 'Não possui'}')
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15)
                    ],
                  );
                },
              ),
              const SizedBox(height: 80)
            ],
          ),
        ),
      ),
    );
  }
}
