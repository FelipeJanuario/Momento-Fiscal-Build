import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/models/consulting_proposal.dart';
import 'package:momentofiscal/core/utilities/consulting_proposal_service_descriptions.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';

class ConsultingProposalForm extends StatefulWidget {
  const ConsultingProposalForm({
    super.key,
    required this.consultingProposal,
    this.consulting,
    required this.onChanged,
    this.onBool,
    this.isClient = false,
  });

  final ConsultingProposal consultingProposal;
  final Consulting? consulting;
  final void Function(ConsultingProposal value) onChanged;
  final void Function(bool value)? onBool;
  final bool isClient;

  @override
  State<ConsultingProposalForm> createState() => _ConsultingProposalForm();
}

class _ConsultingProposalForm extends State<ConsultingProposalForm> {
  late QuillController controller;
  bool _isValid = true;

  final List<Map<String, dynamic>> serviceItems = [
    {
      'title': 'Gestão e Redução do Passivo Fiscal',
      'document': ConsultingProposalServiceDescriptions.passiveTaxManagement,
    },
    {
      'title': 'Reclassificação Fiscal para Fins de Transação',
      'document': ConsultingProposalServiceDescriptions.taxPlanning,
    },
    {
      'title': 'Recuperação de Créditos Tributários',
      'document': ConsultingProposalServiceDescriptions.recoveryOfTaxCredits
    },
    {
      'title': 'Migração de Débitos para PGFN',
      'document': ConsultingProposalServiceDescriptions.migrationOfDebts
    },
    {
      'title': 'Regularização Fiscal e Obtenção de CNDS',
      'document': ConsultingProposalServiceDescriptions
          .taxRegularizationAndObtainingCnds
    },
    {
      'title': 'Diagnóstico de Recuperação Empresarial',
      'requires': 'Regularização Fiscal e Obtenção de CNDS',
      'document':
          ConsultingProposalServiceDescriptions.businessRecoveryDiagnosis
    },
    {
      'title': 'Gestão Financeira e Redução de Passivos',
      'requires': 'Regularização Fiscal e Obtenção de CNDS',
      'document': ConsultingProposalServiceDescriptions
          .financialManagementAndLiabilityReduction
    },
    {
      'title': 'Plano de Redução Estratégica',
      'requires': 'Regularização Fiscal e Obtenção de CNDS',
      'document': ConsultingProposalServiceDescriptions.strategicReductionPlan
    },
    {
      'title': 'Monitoramento Contínuo e Suporte Personalizado',
      'requires': 'Regularização Fiscal e Obtenção de CNDS',
      'document': ConsultingProposalServiceDescriptions.monitoringAndSupport
    },
  ];

  List<Map<String, dynamic>> get filteredServiceItems {
    return serviceItems.where((element) {
      if (element['requires'] == null) return true;
      return widget.consultingProposal.services.contains(element['requires']);
    }).toList();
  }

  void Function(ConsultingProposal value) get onChanged => widget.onChanged;

  void Function(bool value)? get onBool => widget.onBool;

  void _appendDocument(Map<String, dynamic> item) {
    int index = controller.document.length - 1;
    controller.moveCursorToPosition(index);
    controller.replaceText(
      index,
      0,
      item['document'],
      const TextSelection.collapsed(offset: 0),
    );
  }

  void _appendCndsAsLast() {
    const cndsTitle = 'Regularização Fiscal e Obtenção de CNDS';
    final cndsItem =
        serviceItems.firstWhere((item) => item['title'] == cndsTitle);

    // Verifique se o CNDS já está no final
    final delta = controller.document.toDelta();
    final lastContent = delta.toJson().last['insert'];

    if (lastContent == "${cndsItem['document']}\n") {
      Logger.log("Appending CNDS already at the end, skipping append");
      return;
    }

    // Remove o item do documento se ele já existe, para reposicioná-lo no final
    _removeDocument(cndsItem);

    // Adiciona o item "Regularização Fiscal e Obtenção de CNDS" no final do documento
    int endIndex = controller.document.length - 1;
    controller.moveCursorToPosition(endIndex);
    controller.replaceText(
      endIndex,
      0,
      cndsItem['document'],
      const TextSelection.collapsed(offset: 0),
    );
  }

  void _removeDocument(Map<String, dynamic> item) {
    var delta = controller.document.toDelta();

    // Remove todas as operações relacionadas ao documento
    delta.operations.removeWhere((operation) {
      if (operation.attributes == null) return false;
      if (operation.attributes?['service'] == null) return false;

      return operation.attributes?['service'] == item['title'];
    });

    if (delta.operations.isEmpty) {
      delta.insert('\n');
    }

    controller.moveCursorToPosition(0);
    controller.document = Document.fromDelta(delta);
  }

  void _toggleService(ConsultingProposal consultingProposal,
      Map<String, dynamic> item, bool value) {
    if (value) {
      if (!consultingProposal.services.contains(item['title'])) {
        consultingProposal.services.add(item['title']);
        _appendDocument(item);
      }
    } else {
      consultingProposal.services.remove(item['title']);
      _removeDocument(item);
    }

    // Sempre adiciona "Regularização Fiscal e Obtenção de CNDS" ao final
    _appendCndsAsLast();
  }

  @override
  void initState() {
    super.initState();
    if (widget.consultingProposal.description != null &&
        widget.consultingProposal.description!.isNotEmpty) {
      var decodedJson = jsonDecode(widget.consultingProposal.description!);
      var document = Document.fromJson(decodedJson);
      controller = QuillController(
          document: document,
          selection: const TextSelection.collapsed(offset: 0));
    } else {
      // Inicializar o controller com um documento vazio se não houver descrição
      controller = QuillController.basic();
    }
  }

  @override
  void didUpdateWidget(ConsultingProposalForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Verifica se o description mudou e atualiza o QuillController
    if (widget.consultingProposal.description !=
        oldWidget.consultingProposal.description) {
      if (widget.consultingProposal.description != null &&
          widget.consultingProposal.description!.isNotEmpty) {
        var decodedJson = jsonDecode(widget.consultingProposal.description!);
        var document = Document.fromJson(decodedJson);
        setState(() {
          controller = QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0));
        });
      }
    }

    if (widget.isClient) {
      setState(() {
        widget.consultingProposal.description =
            json.encode(controller.document.toDelta().toJson());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Services
        if (widget.consulting?.status != "approved")
          SizedBox(
            height: filteredServiceItems.length * 72,
            child: ListView.builder(
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredServiceItems.length,
              itemBuilder: (context, index) {
                final item = filteredServiceItems[index];

                if (item['requires'] != null &&
                    !widget.consultingProposal.services
                        .contains(item['requires'])) {
                  return const SizedBox.shrink();
                }

                final value =
                    widget.consultingProposal.services.contains(item['title']);

                return GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus(); // Desfoca ao interagir
                  },
                  child: SwitchListTile(
                    title: Text(
                      item['title'],
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: value,
                    onChanged: (value) {
                      setState(() {
                        _toggleService(widget.consultingProposal, item, value);

                        onChanged(widget.consultingProposal);
                      });
                    },
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 20),
        // Description
        if (!widget.isClient && widget.consulting?.status != "approved") ...[
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black),
                left: BorderSide(color: Colors.black),
                right: BorderSide(color: Colors.black),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: controller
            ),
          ),
          Container(
            height: 400,
            decoration: BoxDecoration(
              border: _isValid
                  ? const Border(
                      bottom: BorderSide(color: Colors.black),
                      left: BorderSide(color: Colors.black),
                      right: BorderSide(color: Colors.black),
                    )
                  : Border.all(color: Colors.red),
            ),
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                onTapOutside: (_, __) {
                  setState(() {
                    widget.consultingProposal.description =
                        json.encode(controller.document.toDelta().toJson());
                  });
                  if (onBool != null) {
                    setState(() {
                      _isValid =
                          controller.document.toPlainText().trim().isNotEmpty;
                    });
                    onBool!(_isValid);
                  }
                  onChanged(widget.consultingProposal);
                }
              ),
            ),
          ),
          if (!_isValid)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "O campo de descrição não pode estar vazio.",
                style: TextStyle(color: Colors.red),
              ),
            ),
        ] else if (!widget.isClient && widget.consulting?.status == "approved")
          ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24.0,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      "Proposta foi aprovada. Para finalizar o processo, as informações estão bloqueadas para edição.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Documento',
                        style: TextStyle(fontSize: 18, color: colorPrimaty),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.document_scanner_outlined),
                    ],
                  ),
                  SizedBox(width: 5),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                elevation: 1,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: QuillEditor.basic(controller: controller),
                ),
              ),
            ),
          ],
        const SizedBox(height: 10),
      ],
    );
  }
}
