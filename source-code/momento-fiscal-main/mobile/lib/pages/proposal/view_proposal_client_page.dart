import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/models/consulting_proposal.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';

import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/proposal/my_proposal_client_page.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ViewProposalClientPage extends StatefulWidget {
  const ViewProposalClientPage({super.key, required this.consulting});

  final Consulting consulting;

  @override
  State<ViewProposalClientPage> createState() => _ViewProposalClientPageState();
}

class _ViewProposalClientPageState extends State<ViewProposalClientPage> {
  ConsultingProposal consultingProposal = ConsultingProposal();
  String formattedDate = "";
  bool isLoading = true; // Variável para controlar o estado de carregamento
  late QuillController _controller;
  Document? _document;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(
      DateTime.parse(widget.consulting.createdAt.toString()),
    );
    getProposal();
  }

  Future<void> _saveAndGeneratePDF(BuildContext context) async {
    try {
      Uint8List? pdf = await _fetchPDF();

      if (pdf == null) return;

      // Oppening the PDF file on the device
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/proposta ${consultingProposal.consultingId}.pdf');
      await file.writeAsBytes(pdf);

      // Open the PDF file with the device's preferred app
      await OpenFilex.open(file.path);
    } catch (e) {
      Exception(
        "[CreateProposalPage][_CreateProposalPageState][_saveAndGeneratePDF] Error saving proposal $e",
      );
    }
  }

  Future<Uint8List?> _fetchPDF() async {
    try {
      return await consultingProposal.fetchPDF();
    } catch (e) {
      Exception(
          "[CreateProposalPage][_CreateProposalPageState][_fetchPDF] Error fetching PDF $e");
    }

    return null;
  }

  void getProposal() async {
    try {
      setState(() {
        isLoading = true; // Ativa o loading
      });

      var proposal = await consultingProposal.getConsultingProposal(
        queryParameters: {"query[consulting_id]": widget.consulting.id},
      );

      if (proposal != null) {
        setState(() {
          consultingProposal = proposal;
          // Verifique se a descrição não é nula e não está vazia
          if (consultingProposal.description != null &&
              consultingProposal.description!.isNotEmpty) {
            _document =
                Document.fromJson(jsonDecode(consultingProposal.description!));
            _controller = QuillController(
                readOnly: true,
                document: _document!,
                selection: const TextSelection.collapsed(offset: 0));
          }

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Desativa o loading mesmo em caso de erro
      });
      Exception('Erro ao carregar a proposta: $e');
    }
  }

  Future updateProposal({
    required String status,
    required String textTitle,
    required String textContent,
    bool isWaiting = false,
  }) async {
    return showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Center(child: Text(textTitle)),
            content: SizedBox(
              height: isWaiting ? 190 : 80,
              child: Column(
                children: [
                  Text(
                      "Deseja $textContent para a consultoria de número ${widget.consulting.id}"),
                  if (isWaiting) ...[
                    const SizedBox(height: 5),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          // Campo para adicionar comentário
                          TextFormField(
                            controller: _commentController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Por favor, digite seu comentário";
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Comentário',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _commentController.text = "";
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    backgroundColor: colorPrimaty,
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white),
                  )),
              TextButton(
                onPressed: () async {
                  if (isWaiting) {
                    bool formValidate = _formKey.currentState!.validate();
                    if (!formValidate) return;
                  }

                  try {
                    await ConsultingRailsService().patchConsulting(
                        consultingId: widget.consulting.id!,
                        updatedFields: {
                          "status": status,
                        });

                    consultingProposal.comment = _commentController.text;
                    await consultingProposal.save();

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MyProposalClientPage(),
                      ),
                    );
                  } catch (e) {
                    Exception('Erro update consulting patch $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: colorTertiary,
                ),
                child: const Text(
                  "Confirmar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proposta',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Exibe o loading
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    if (widget.consulting.status == "in_progress") ...[
                      const Text('Como você define sua proposta?'),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 1,
                            backgroundColor: colorPrimaty,
                          ),
                          onPressed: () async {
                            await updateProposal(
                              status: "approved",
                              textTitle: "Aceitar a Proposta?",
                              textContent: 'aceitar a proposta',
                            );
                          },
                          child: const Text(
                            'Aceitar Proposta?',
                            style: TextStyle(color: Colors.white),
                          )),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 1,
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            await updateProposal(
                              status: "failed",
                              textTitle: "Rejeitar a Proposta?",
                              textContent: 'rejeitar a proposta',
                            );
                          },
                          child: const Text(
                            'Rejeitar Proposta?',
                            style: TextStyle(color: Colors.white),
                          )),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 1,
                            backgroundColor:
                                const Color.fromARGB(255, 255, 209, 59),
                          ),
                          onPressed: () async {
                            await updateProposal(
                                status: "waiting",
                                textTitle: "Solicitar Revisão?",
                                textContent: 'solicitar revisão',
                                isWaiting: true);
                          },
                          child: const Text(
                            'Solicitar Revisão?',
                            style: TextStyle(color: Colors.white),
                          )),
                    ] else if (widget.consulting.status == "approved") ...[
                      const Text(
                        "Essa proposta já foi aceita",
                        style: TextStyle(color: colorPrimaty),
                      )
                    ] else if (widget.consulting.status == "failed") ...[
                      Text(
                        "Essa proposta foi rejeitada",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      )
                    ] else if (widget.consulting.status == "waiting") ...[
                      const Text(
                        "Essa proposta está em análise, aguarde a revisão do consultor",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 209, 59),
                        ),
                      )
                    ],
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                                fontSize: 12, color: colorPrimaty),
                          ),
                          const SizedBox(width: 15),
                          const Text('Data de Criação'),
                        ],
                      ),
                    ),
                    if (consultingProposal.id != null)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Soluções',
                            style: TextStyle(fontSize: 18, color: colorPrimaty),
                          ),
                          SizedBox(width: 5),
                          Icon(Icons.lightbulb_outline)
                        ],
                      ),
                    // Services
                    SizedBox(
                      height: consultingProposal.services.length * 56,
                      child: ListView.builder(
                        primary: false,
                        itemCount: consultingProposal.services.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                              title: Text(consultingProposal.services[index]));
                        },
                      ),
                    ),
                    if (_document != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Documento',
                                  style: TextStyle(
                                      fontSize: 18, color: colorPrimaty),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.document_scanner_outlined),
                              ],
                            ),
                            const SizedBox(width: 5),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 3,
                                  backgroundColor: colorTertiary,
                                ),
                                onPressed: () async {
                                  _saveAndGeneratePDF(context);
                                },
                                child: const Text(
                                  'Gerar PDF',
                                  style: TextStyle(color: Colors.white),
                                ))
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          elevation: 1,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: QuillEditor.basic(
                                controller: _controller,
                              ),
                            ),
                          ),
                        ),   
                    ] else ...[
                      const Text(
                          'Aguarde o consultor realizar o documento da Proposta')
                    ]
                  ],
                ),
              ),
            ),
    );
  }
}
