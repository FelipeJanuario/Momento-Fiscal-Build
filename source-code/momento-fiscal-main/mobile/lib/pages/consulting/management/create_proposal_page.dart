import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/card_upgrade_plans.dart';
import 'package:momentofiscal/components/consulting_card.dart';
import 'package:momentofiscal/components/consulting_proposals/consulting_proposal_form.dart';
import 'package:momentofiscal/core/models/consulting.dart';
import 'package:momentofiscal/core/models/consulting_proposal.dart';
import 'package:momentofiscal/core/services/consulting/consulting_rails_service.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/services/user_institution/user_institution_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/consulting/management/consulting_management_page.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// ignore: must_be_immutable
class CreateProposalPage extends StatefulWidget {
  Consulting? consulting;
  final String? cnpj;
  final double? debtValue;
  final int? debtsCount;

  CreateProposalPage(
      {super.key, this.consulting, this.debtValue, this.cnpj, this.debtsCount});

  @override
  State<CreateProposalPage> createState() => _CreateProposalPageState();
}

class _CreateProposalPageState extends State<CreateProposalPage> {
  bool isPlanejament = false;
  QuillController controller = QuillController.basic();

  ConsultingProposal consultingProposal = ConsultingProposal();
  bool isSaving = false;
  bool isOpeningPDF = false;
  bool isSharingPDF = false;
  String errorMessage = '';
  String? userRole;
  String? userId;
  bool isValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.consulting != null) {
      getProposal();
    } else {
      getIdUser();
    }
  }

  Future<void> getIdUser() async {
    userId = await storage.read(key: 'id');
  }

  void getProposal() async {
    try {
      userRole = await storage.read(key: 'role');

      var proposal = await consultingProposal.getConsultingProposal(
          queryParameters: {"query[consulting_id]": widget.consulting?.id});

      if (proposal != null) {
        setState(() {
          consultingProposal = proposal; // Atualiza o objeto com o novo valor
        });
      }
    } catch (e) {
      log('Erro ao carregar a proposta: $e');
    }
  }

  Future<void> _saveAndGeneratePDF(BuildContext context) async {
    if (isOpeningPDF) return;

    setState(() {
      isOpeningPDF = true;
    });

    if (!_validateForm()) {
      setState(() {
        isOpeningPDF = false;
      });
      return;
    } else {
      try {
        await _saveProposal(context);
        Uint8List? pdf = await _fetchPDF();

        if (pdf == null) return;

        // Oppening the PDF file on the device
        final directory = await getApplicationDocumentsDirectory();
        final file = File(
            '${directory.path}/proposta ${consultingProposal.consultingId}.pdf');
        await file.writeAsBytes(pdf);

        // Open the PDF file with the device's preferred app
        await OpenFilex.open(file.path);

        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboadPage(),
          ),
        );
      } catch (e, stackTrace) {
        log(
          "[CreateProposalPage][_CreateProposalPageState][_saveAndGeneratePDF] Error saving proposal",
          error: e,
          stackTrace: stackTrace,
        );
      }
      setState(() {
        isOpeningPDF = false;
      });
    }
  }

  Future<void> _saveAndSharePDF(BuildContext context) async {
    if (isSharingPDF) return;

    setState(() {
      isSharingPDF = true;
    });

    if (!_validateForm()) {
      setState(() {
        isSharingPDF = false;
      });
      return;
    } else {
      try {
        await _saveProposal(context);
        Uint8List? pdf = await _fetchPDF();

        if (pdf == null) return;

        _sharePdf(pdf);

        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DashboadPage(),
          ),
        );
      } catch (e, stackTrace) {
        log(
          "[CreateProposalPage][_CreateProposalPageState][_saveAndGeneratePDF] Error saving proposal",
          error: e,
          stackTrace: stackTrace,
        );
      }
      setState(() {
        isSharingPDF = false;
      });
    }
  }

  Future<void> _saveAndSendProposal(BuildContext context) async {
    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      await _saveProposal(context);
      _showSuccessDialog();
    } catch (e, stackTrace) {
      log(
        "[CreateProposalPage][_CreateProposalPageState][_saveAndSendProposal] Error saving proposal",
        error: e,
        stackTrace: stackTrace,
      );
    }

    setState(() => isSaving = false);
  }

  Future<void> _saveProposal(BuildContext context) async {
    if (!_validateForm()) return;

    if (widget.cnpj != null) {
      var institution =
          await InstitutionRailsService().getInstitution(cnpj: widget.cnpj!);

      if (institution != null) {
        var userInstitution = await UserInstitutionRailsService()
            .getUserInsitution(institutionId: institution.id);

        if (userInstitution != null) {
          var consultingResponse =
              await ConsultingRailsService().createConsulting(
            debtValue: widget.debtValue!,
            debtsCount: widget.debtsCount,
            idUser: userInstitution['user_id'],
            idConsultant: userId,
            status: "in_progress",
          );
          if (consultingResponse.statusCode == 201) {
            String consultingId =
                json.decode(consultingResponse.body)['id'].toString();

            try {
              consultingProposal.consultingId = consultingId;
              await consultingProposal.save();
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
                    content: Text('Ocorreu um erro ao salvar a proposta.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              Exception("Error in $e");
            }
          } else if (consultingResponse.body.contains('Unauthorized')) {
            cardUpgradePlans(
              // ignore: use_build_context_synchronously
              context: context,
              text:
                  'Seu plano atual excedeu a quantidade de proposta. Faça o upgrade para continuar.',
            );
          }
        }
      } else {
        var consultingResponse = await ConsultingRailsService()
            .createConsulting(
                debtValue: widget.debtValue!,
                debtsCount: widget.debtsCount,
                idConsultant: userId,
                status: 'waiting_for_user_creation');

        if (consultingResponse.statusCode == 201) {
          String consultingId =
              json.decode(consultingResponse.body)['id'].toString();

          try {
            consultingProposal.consultingId = consultingId;
            await consultingProposal.save();
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
                  content: Text('Ocorreu um erro ao salvar a proposta.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            Exception("Error in $e");
          }
        } else if (consultingResponse.body.contains('Unauthorized')) {
          cardUpgradePlans(
            // ignore: use_build_context_synchronously
            context: context,
            text:
                'Seu plano atual excedeu a quantidade de proposta. Faça o upgrade para continuar.',
          );
        }
      }
    }
  }

  Future<Uint8List?> _fetchPDF() async {
    try {
      return await consultingProposal.fetchPDF();
    } catch (e, stackTrace) {
      log(
        "[CreateProposalPage][_CreateProposalPageState][_fetchPDF] Error fetching PDF",
        error: e,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<void> _sharePdf(Uint8List pdf) async {
    final result = await Share.shareXFiles(
      [XFile.fromData(pdf, name: 'proposta.pdf', mimeType: 'application/pdf')],
      text: 'Proposta de Consultoria',
    );

    if (result.status == ShareResultStatus.success) {
      log('PDF shared successfully');
    } else {
      log('Error sharing PDF: ${result.status}');
    }
  }

  bool _validateForm() {
    if (consultingProposal.services.isEmpty) {
      setState(() => errorMessage = 'Selecione pelo menos uma opção');
      return false;
    }

    setState(() => errorMessage = '');
    return true;
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
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
              child: const Text('Continuar'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ConsultingManagementPage(
                      isConsultant: userRole == "consultant" ? true : false,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.consulting != null ? 'Editar Proposta' : "Criar Proposta",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  height: 100,
                  child: Image.asset('assets/images/momentofiscalcolorido.png',
                      fit: BoxFit.cover),
                ),
              ),
              if (widget.consulting != null) ...[
                const SizedBox(height: 10),
                ConsultingCard(
                  consultingManagement: widget.consulting!,
                ),
                const SizedBox(height: 10),
                if (widget.consulting!.status == "waiting") ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Comentário do Cliente:",
                          style: TextStyle(color: colorPrimaty),
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.consulting?.clientName ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    consultingProposal.comment ??
                                        "Carregando...",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${consultingProposal.updatedAt != null ? "Última atualização: ${DateFormat('dd/MM/yyyy HH:mm').format(consultingProposal.updatedAt!)}" : ""} ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              Text(errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ConsultingProposalForm(
                consultingProposal: consultingProposal,
                consulting: widget.consulting,
                onChanged: (value) {
                  setState(() {
                    consultingProposal = value;
                  });
                },
                onBool: (value) {
                  setState(() {
                    isValid = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    if (widget.consulting?.status != "approved") ...[
                      ElevatedButton(
                        onPressed: consultingProposal.description != null &&
                                consultingProposal.description!.isNotEmpty
                            ? () {
                                _saveAndGeneratePDF(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        child: isOpeningPDF
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Salvar e Gerar PDF',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                      IconButton(
                        onPressed: consultingProposal.description != null &&
                                consultingProposal.description!.isNotEmpty
                            ? () {
                                _saveAndSharePDF(context);
                              }
                            : null, //
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: isSharingPDF
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Icon(Icons.share, color: Colors.white),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (widget.consulting != null) {
                            _saveAndSendProposal(context);
                          } else {
                            if (isValid) {
                              if (widget.cnpj != null) {
                                var institution =
                                    await InstitutionRailsService()
                                        .getInstitution(cnpj: widget.cnpj!);

                                if (institution != null) {
                                  var userInstitution =
                                      await UserInstitutionRailsService()
                                          .getUserInsitution(
                                              institutionId: institution.id);

                                  if (userInstitution != null) {
                                    var consultingResponse =
                                        await ConsultingRailsService()
                                            .createConsulting(
                                      debtValue: widget.debtValue!,
                                      debtsCount: widget.debtsCount,
                                      idUser: userInstitution['user_id'],
                                      idConsultant: userId,
                                      status: "in_progress",
                                    );
                                    if (consultingResponse.statusCode == 201) {
                                      String consultingId = json
                                          .decode(consultingResponse.body)['id']
                                          .toString();

                                      try {
                                        consultingProposal.consultingId =
                                            consultingId;
                                        await consultingProposal.save();

                                        return showDialog<void>(
                                          // ignore: use_build_context_synchronously
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Proposta Criada'),
                                              content:
                                                  const SingleChildScrollView(
                                                child: ListBody(
                                                  children: <Widget>[
                                                    Text(
                                                        'Relatório criado com sucesso!'),
                                                  ],
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    elevation: 3,
                                                    backgroundColor:
                                                        colorTertiary,
                                                  ),
                                                  child: const Text(
                                                    'Continuar',
                                                    style: TextStyle(
                                                        color: Colors.white),
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
                                        if (e.message
                                            .contains('Unauthorized')) {
                                          cardUpgradePlans(
                                            // ignore: use_build_context_synchronously
                                            context: context,
                                            text:
                                                'Seu plano atual excedeu a quantidade de proposta. Faça o upgrade para continuar.',
                                          );
                                        } else {
                                          // ignore: use_build_context_synchronously
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Ocorreu um erro ao salvar a proposta.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        Exception("Error in $e");
                                      }
                                    } else if (consultingResponse.body
                                        .contains('Unauthorized')) {
                                      cardUpgradePlans(
                                        // ignore: use_build_context_synchronously
                                        context: context,
                                        text:
                                            'Seu plano atual excedeu a quantidade de proposta. Faça o upgrade para continuar.',
                                      );
                                    }
                                  }
                                } else {
                                  var consultingResponse =
                                      await ConsultingRailsService()
                                          .createConsulting(
                                              debtValue: widget.debtValue!,
                                              debtsCount: widget.debtsCount,
                                              idConsultant: userId,
                                              status:
                                                  'waiting_for_user_creation');

                                  if (consultingResponse.statusCode == 201) {
                                    String consultingId = json
                                        .decode(consultingResponse.body)['id']
                                        .toString();

                                    try {
                                      consultingProposal.consultingId =
                                          consultingId;
                                      await consultingProposal.save();

                                      return showDialog<void>(
                                        // ignore: use_build_context_synchronously
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title:
                                                const Text('Proposta Criada'),
                                            content:
                                                const SingleChildScrollView(
                                              child: ListBody(
                                                children: <Widget>[
                                                  Text(
                                                      'Relatório criado com sucesso!'),
                                                ],
                                              ),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 3,
                                                  backgroundColor:
                                                      colorTertiary,
                                                ),
                                                child: const Text(
                                                  'Continuar',
                                                  style: TextStyle(
                                                      color: Colors.white),
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
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Ocorreu um erro ao salvar a proposta.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      Exception("Error in $e");
                                    }
                                  } else if (consultingResponse.body
                                      .contains('Unauthorized')) {
                                    cardUpgradePlans(
                                      // ignore: use_build_context_synchronously
                                      context: context,
                                      text:
                                          'Seu plano atual excedeu a quantidade de proposta. Faça o upgrade para continuar.',
                                    );
                                  }
                                }
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Enviar Relatório',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
