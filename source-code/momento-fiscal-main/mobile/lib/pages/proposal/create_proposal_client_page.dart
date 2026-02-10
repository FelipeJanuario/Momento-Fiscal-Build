import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:momentofiscal/components/card_upgrade_plans.dart';
import 'package:momentofiscal/components/consulting_proposals/consulting_proposal_form.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/models/consulting_proposal.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';

class CreateProposalClientPage extends StatefulWidget {
  final String idUser;
  final double debtValue;
  final int? debtsCount;
  const CreateProposalClientPage({
    super.key,
    required this.idUser,
    required this.debtValue,
    this.debtsCount,
  });

  @override
  State<CreateProposalClientPage> createState() =>
      _CreateProposalClientPageState();
}

class _CreateProposalClientPageState extends State<CreateProposalClientPage> {
  ConsultingProposal consultingProposal = ConsultingProposal();

  // Função para validar se ao menos um switch está selecionado
  bool isAnySwitchSelected() {
    return consultingProposal.services.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relatório de Soluções',
          style: TextStyle(color: Colors.white),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup()],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 15),
            SizedBox(
              height: 100,
              child: Image.asset('assets/images/momentofiscalcolorido.png',
                  fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            ConsultingProposalForm(
                isClient: true,
                consultingProposal: consultingProposal,
                onChanged: (value) {
                  setState(() {
                    consultingProposal = value;
                  });
                }),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorTertiary,
              ),
              onPressed: () async {
                if (isAnySwitchSelected()) {
                  var consultingResponse = await ConsultingRailsService()
                      .createConsulting(
                          debtValue: widget.debtValue,
                          debtsCount: widget.debtsCount,
                          idUser: widget.idUser);

                  if (consultingResponse.statusCode == 201) {
                    String consultingId =
                        json.decode(consultingResponse.body)['id'].toString();

                    try {
                      consultingProposal.consultingId = consultingId;

                      await consultingProposal.save();

                      return showDialog<void>(
                        // ignore: use_build_context_synchronously
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Proposta Criada'),
                            content: const SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  Text('Relatório enviado com sucesso!'),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 3,
                                  backgroundColor: colorTertiary,
                                ),
                                child: const Text(
                                  'Continuar',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DashboadPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } on HttpException catch (e) {
                      if (e.message.contains('Unauthorized')) {
                        cardUpgradePlans(
                          // ignore: use_build_context_synchronously
                          context: context,
                          text:
                              'Seu plano atual excedeu a quantidade de proposta. Faça o upgrade para continuar.',
                        );
                      } else {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Ocorreu um erro ao salvar a proposta.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      Exception(
                          "[CreateProposalPage][_CreateProposalPageState][_saveProposal] Error saving proposal $e");
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Selecione pelo menos uma proposta!"),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text(
                "Enviar Proposta",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
