import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/core/models/institution.dart';
import 'package:momentofiscal/core/services/institution/institution_rails_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/text_fields.dart';
import 'package:momentofiscal/core/utilities/validations.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';

class NewInstitutionPage extends StatefulWidget {
  final Institution? institution;
  const NewInstitutionPage({super.key, this.institution});

  @override
  State<NewInstitutionPage> createState() => _NewInstitutionPageState();
}

class _NewInstitutionPageState extends State<NewInstitutionPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController responsibleNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController cnpjController = TextEditingController();
  TextEditingController responsibleCpfController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController cellPhoneController = TextEditingController();
  String? oabState;
  TextEditingController oabNumberPhoneController = TextEditingController();
  TextEditingController limitDebtController = TextEditingController();

  bool hasCertificate = false;

  @override
  void initState() {
    super.initState();

    if (widget.institution != null) {
      editResquest();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
    ));
  }

  void editResquest() {
    responsibleNameController.text = widget.institution!.responsibleName;
    emailController.text = widget.institution!.email;
    cnpjController.text = formatNumberInCnpj(widget.institution!.cnpj);
    responsibleCpfController.text =
        formatCpf(widget.institution!.responsibleCpf);
    phoneController.text = widget.institution!.phone;
    cellPhoneController.text = widget.institution!.cellPhone;
    limitDebtController.text = NumberFormat.decimalPattern('pt_BR')
        .format(widget.institution!.limitDebt);
  }

  Future<void> _clickButton(BuildContext context) async {
    bool formValidate = _formKey.currentState!.validate();
    if (!formValidate) return;

    if (widget.institution != null) {
      var patchInstitution = await InstitutionRailsService().putInstitution(
        id: widget.institution!.id,
        responsibleName: responsibleNameController.text,
        email: emailController.text,
        cnpj: formatCnpj(cnpjController.text),
        responsibleCpf: responsibleCpfController.text,
        phone: phoneController.text,
        cellPhone: cellPhoneController.text,
        limitDebt: double.parse(
            formatNumber(limitDebtController.text).replaceAll(',', '.')),
      );

      if (patchInstitution.statusCode == 200) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) {
            return PopScope(
              canPop: false,
              child: AlertDialog(
                title: const Text('Instituição atualizada com sucesso!'),
                content: const Text(
                    'A nova instituição foi atualizada com sucesso. Para visualizar, clique em "Minhas Empresas".'),
                actions: [
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 3,
                      backgroundColor: colorTertiary,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const DashboadPage()));
                    },
                    child: const Text('Entendi',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      } else if (patchInstitution.statusCode == 422) {
        _showError(json.decode(patchInstitution.body).toString());
      }
    } else {
      // var createInstitution = await InstitutionRailsService().createInstitution(
      //   responsibleName: responsibleNameController.text,
      //   email: emailController.text,
      //   cnpj: formatCnpj(cnpjController.text),
      //   responsibleCpf: responsibleCpfController.text,
      //   phone: phoneController.text,
      //   cellPhone: cellPhoneController.text,
      //   limitDebt: double.parse(
      //       formatNumber(limitDebtController.text).replaceAll(',', '.')),
      // );

      // if (createInstitution.statusCode == 201) {
      //   showDialog(
      //     // ignore: use_build_context_synchronously
      //     context: context,
      //     builder: (context) {
      //       return PopScope(
      //         canPop: false,
      //         child: AlertDialog(
      //           title: const Text('Instituição cadastrada com sucesso!'),
      //           content: const Text(
      //               'A nova instituição foi cadastrada com sucesso. Para visualizar, clique em "Minhas Empresas".'),
      //           actions: [
      //             TextButton(
      //               onPressed: () {
      //                 Navigator.of(context).push(MaterialPageRoute(
      //                     builder: (context) => const DashboadPage()));
      //               },
      //               style: ElevatedButton.styleFrom(
      //                   elevation: 2,
      //                   backgroundColor: colorTertiary,
      //                   padding: const EdgeInsets.symmetric(horizontal: 20)),
      //               child: const Text(
      //                 'Entendi',
      //                 style: TextStyle(color: Colors.white),
      //               ),
      //             ),
      //           ],
      //         ),
      //       );
      //     },
      //   );
      // } else if (createInstitution.statusCode == 422) {
      //   _showError(json.decode(createInstitution.body).toString());
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.institution != null ? 'Editar Empresa' : 'Cadastrar Empresa',
            style: const TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Form(
                key: _formKey,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      textFormField(
                        controller: responsibleNameController,
                        validator: (value) => validatorName(value),
                        hint: 'Digite o nome do responsavél',
                        label: 'Responsavél pela plataforma',
                        icons: Icons.person,
                        size: 50.0,
                      ),
                      const SizedBox(height: 20),
                      textFormField(
                        controller: emailController,
                        validator: (value) => validatorEmail(value),
                        hint: 'Digite seu e-mail para contato',
                        label: 'E-mail para contato',
                        size: 50,
                        icons: Icons.email,
                        textInputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      textFormField(
                        controller: cnpjController,
                        validator: (value) => validatorCnpj(value),
                        hint: 'Digite seu CNPJ da empresa',
                        label: 'CNPJ da empresa',
                        size: 50,
                        readOnly: widget.institution != null ? true : false,
                        icons: Icons.business,
                        textInputType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        inputFormatters: [formatterCnpj],
                      ),
                      const SizedBox(height: 20),
                      textFormField(
                        controller: responsibleCpfController,
                        validator: (value) {
                          return null;
                        },
                        hint: 'Digite o CPF do sócio majoritário',
                        label: 'CPF do sócio majoritário',
                        size: 50,
                        readOnly: widget.institution != null ? true : false,
                        icons: Icons.account_box,
                        textInputType: const TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        inputFormatters: [formatterCpf],
                      ),
                      const SizedBox(height: 20),
                      textFormField(
                        controller: phoneController,
                        validator: (value) => validatorPhone(value),
                        hint: 'Digite o telefone',
                        label: 'Telefone',
                        size: 50,
                        icons: Icons.phone,
                        textInputType: TextInputType.phone,
                        inputFormatters: [formatterPhone],
                      ),
                      const SizedBox(height: 20),
                      textFormField(
                        controller: cellPhoneController,
                        validator: (value) => validatorCellPhone(value),
                        hint: 'Digite o celular',
                        label: 'Celular',
                        size: 50,
                        icons: Icons.phone_android,
                        textInputType: TextInputType.phone,
                        inputFormatters: [formatterCellPhone],
                      ),
                      // const SizedBox(height: 10),
                      // SwitchListTile(
                      //   title: const Text('Consultor de serviço e Cliente?'),
                      //   value: hasCertificate,
                      //   onChanged: (value) {
                      //     setState(() {
                      //       hasCertificate = value;
                      //       if (!hasCertificate) {
                      //         //zerar parametros que vai para requisição
                      //       }
                      //     });
                      //   },
                      // ),
                      // const SizedBox(height: 10),
                      // if (hasCertificate)
                      //   const Text('Estado da OAB', style: labelStyle),
                      // if (hasCertificate) const SizedBox(height: 10),
                      // if (hasCertificate)
                      //   dropdownInput(
                      //       value: oabState,
                      //       onChanged: (selectedStates) {
                      //         setState(() {
                      //           oabState = selectedStates;
                      //         });
                      //       },
                      //       icons: Icons.map_outlined,
                      //       items: dropdownItemsStatesBrasil,
                      //       hint: 'Selecione o estado da OAB'),
                      // if (hasCertificate) const SizedBox(height: 20),
                      // if (hasCertificate)
                      //   textFormField(
                      //       controller: oabNumberPhoneController,
                      //       validator: (value) => validatorLenghtOab(value),
                      //       hint: 'OAB nº',
                      //       textInputType: TextInputType.number,
                      //       label: 'Digite o número de sua OAB',
                      //       icons: Icons.co_present_outlined,
                      //       size: 50.0),
                      const SizedBox(height: 20),
                      textFormField(
                          controller: limitDebtController,
                          validator: (value) => validatorMoney(value),
                          hint: 'Exemplo: R\$ 1000,00',
                          label: 'Limite da dívida',
                          icons: Icons.monetization_on,
                          textInputType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            CurrencyInputFormatter(
                              thousandSeparator: ThousandSeparator.Period,
                              mantissaLength: 2,
                            )
                          ],
                          size: 50.0),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              elevation: 3,
                              backgroundColor: colorTertiary,
                              fixedSize: const Size.fromWidth(500)),
                          child: Text(
                            widget.institution != null
                                ? 'Atualizar'
                                : 'Cadastrar',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Inter',
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            _clickButton(context);
                          }),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
