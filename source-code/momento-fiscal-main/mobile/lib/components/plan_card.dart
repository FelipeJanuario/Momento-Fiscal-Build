import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/core/models/subscription.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/core/services/freePlanUsage/free_plans_usages_rails_servide.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/core/utilities/text_fields.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/services/billing/in_app_purchase_service.dart';

class PlanCard extends StatefulWidget {
  final PurchasableProduct product;
  final List<Subscription> subscription;
  final Color colorButton;
  final Widget buttonWidget;
  final bool isPlanButton;

  const PlanCard({
    super.key,
    required this.product,
    required this.subscription,
    required this.colorButton,
    required this.buttonWidget,
    required this.isPlanButton,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _isLoading = false;
  bool isPlanUpdate = false;
  String? id;
  List<StoreProduct>? productDetails;
  bool isCompleteCustomer = false;

  // void _showPlan(String textPlan) {
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text(textPlan),
  //     backgroundColor: Theme.of(context).primaryColor,
  //   ));
  // }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isIOS) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    try {
      id = await storage.read(key: 'id');

      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        setState(() {
          productDetails = offerings.current!.availablePackages
              .map((package) => package.storeProduct)
              .toList();
        });
      }
    } catch (e) {
      Exception('Erro ao buscar produtos: $e');
    }
  }

  void showAlertDialogSucess(String priceName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Plano Adquirido com Sucesso!"),
        content: Text("Foi adicionado o novo $priceName ao seu usuário."),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: widget.colorButton,
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const DashboadPage()),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text('Entendi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showAlertDialogUpdate() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Solicitar alteração do Plano"),
        content: const Text("Deseja alterar seu Plano?"),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: const Color.fromARGB(255, 4, 61, 167),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(false);
            },
            child: const Text("Não", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              elevation: 3,
              backgroundColor: colorTertiary,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();

              showAlertDialogSucess(widget.product.title);
            },
            child: const Text("Sim", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void showAlertDialogRemove(String subscriptionId) async {
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Solicitar cancelamento do Plano"),
          content: const Text(
            "Será cancelado no final da fatura do plano escolhido. Em caso de dúvidas, entre em contato com o suporte.",
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorPrimaty,
              ),
              onPressed: () {
                Navigator.of(ctx).pop(false);
              },
              child: const Text("Não", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorTertiary,
              ),
              onPressed: isLoading
                  ? null // Desativa o botão durante o carregamento
                  : () async {
                      setState(() {
                        isLoading = true;
                      });

                      try {
                        // TODO
                        // await InAppPurchaseService.instance.cancelSubscription(subscriptionId: subscriptionId);
                        await storage.write(
                            key: 'subscriptionPlatform', value: null);
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const DashboadPage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Sim", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _handlePayment(PurchasableProduct product) async {
    if (!widget.isPlanButton && !_isLoading) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (!kIsWeb && Platform.isIOS) {
          final selectedProduct = productDetails?.firstWhere(
            (product) => product.title == widget.product.title,
          );

          var currentPlatform = await storage.read(key: 'subscriptionPlatform');

          try {
            if (widget.subscription.any((item) => item.amount == '0') ||
                widget.subscription.isEmpty) {
              if (currentPlatform == "google_play") {
                // ignore: use_build_context_synchronously
                showDialogForExistingPlan(context, "Android");
              } else {
                var responseGetFreeStatus = await FreePlansUsagesRailsService()
                    .getFreePlansUsages(userId: id!);

                if (selectedProduct?.identifier == 'plan_id1') {
                  var responseFree = await FreePlansUsagesRailsService()
                      .createFreePlanUsage(userId: id!);
                  if (json
                      .decode(responseGetFreeStatus)['expired_plan_ids']
                      .isNotEmpty) {
                    showDialog(
                        // ignore: use_build_context_synchronously
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              content: const SizedBox(
                                height: 100,
                                child: Column(
                                  children: [
                                    Text(
                                      'Plano Expirado',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "É necessário fazer uma nova assinatura pois o plano foi free foi expirado.",
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 3,
                                    backgroundColor: widget.colorButton,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Entendi',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ]);
                        });
                  } else if (json.decode(responseFree.body)['message'] ==
                      "Plano gratuito registrado com sucesso") {
                    showDialog(
                        // ignore: use_build_context_synchronously
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              content: SizedBox(
                                height: 100,
                                child: Column(
                                  children: [
                                    Text(
                                      json.decode(responseFree.body)['message'],
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      "Seu plano Free foi adquirido com sucesso",
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 3,
                                    backgroundColor: widget.colorButton,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const DashboadPage()),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                  child: const Text('Entendi',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ]);
                        });
                  } else if (json.decode(responseFree.body)['message'] ==
                      "Plano gratuito já utilizado") {
                    showDialog(
                        // ignore: use_build_context_synchronously
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            content: SizedBox(
                              height: 100,
                              child: Column(
                                children: [
                                  Text(
                                    json.decode(responseFree.body)['message'],
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    "Você já está utilizando o Plano Free com duração de uma semana",
                                    textAlign: TextAlign.center,
                                  )
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 3,
                                  backgroundColor: colorTertiary,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  " Entendi",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        });
                  }
                } else if (selectedProduct != null) {
                  await Purchases.purchaseStoreProduct(selectedProduct).then(
                    (value) async {
                      isCompleteCustomer = true;
                      if (json
                          .decode(responseGetFreeStatus)['free_plan_usages']
                          .isEmpty) {
                        await FreePlansUsagesRailsService().createFreePlanUsage(
                            userId: id!, status: 'upgraded');
                      } else {
                        await FreePlansUsagesRailsService().putFreePlansUsages(
                            id: json
                                .decode(responseGetFreeStatus)[
                                    'free_plan_usages'][0]['id']
                                .toString(),
                            status: "upgraded");
                      }
                    },
                  );
                  await storage.write(
                      key: 'subscriptionPlatform', value: 'apple');

                  AuthRailsService()
                      .patchMapUser(id: id!, updatedFields: {"ios_plan": true});
                } else {
                  Exception("Produto não encontrado");
                }
              }
            } else {
              setState(() {
                isPlanUpdate = true;
              });
            }
          } catch (e) {
            Exception('Erro platform ios $e');
          } finally {
            if (currentPlatform == "google_play") {
              // ignore: use_build_context_synchronously
              showDialogForExistingPlan(context, "Android");
            } else if (isCompleteCustomer == false) {
              Logger.log("Plano Cancelado");
            } else {
              setState(() {
                showAlertDialogSucess(product.title);
              });
            }
          }
        } else {
          String? iosPlan = await storage.read(key: 'iosPlan');
          if (iosPlan == "true") {
            // ignore: use_build_context_synchronously
            showDialogForExistingPlan(context, "Apple");
          } else {
            if (widget.subscription.any((item) => item.amount == '0') ||
                widget.subscription.isEmpty) {
              await storage.write(key: 'subscriptionPlatform', value: 'google_play');

              await InAppPurchaseService.instance.purchaseSubscription(
                product,
                onSuccess: () {
                  setState(() {
                    _isLoading = false;
                    isPlanUpdate = false;
                    showAlertDialogSucess(product.title);
                    if (widget.subscription.any((item) => item.amount == '0')) {
                      InAppPurchaseService.instance.cancelSubscription(
                        subscriptionId: widget.subscription.first.id!,
                      );
                    }
                  });
                },
                onError: (String error) {
                  setState(() {
                    _isLoading = false;
                  });
                  Logger.log('Purchase error: $error');
                },
              );
            } else {
              setState(() {
                isPlanUpdate = true;
              });
            }
          }
        }
      } catch (e) {
        Exception('Erro em PlanCard: $e');
      } finally {
        setState(() {
          _isLoading = false;
          if (!isPlanUpdate) {
            if (product.isFree && !kIsWeb && Platform.isAndroid) {
              showAlertDialogSucess(product.title);
            }
          } else {
            if (!kIsWeb && Platform.isAndroid) {
              showAlertDialogUpdate();
            }
          }
        });
      }
    } else {
      showAlertDialogRemove(widget.subscription.first.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = MediaQuery.of(context).size.height * 0.7;

    return SizedBox(
      height: cardHeight,
      child: Stack(
        children: [
          Card(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              child: buildCardContent(),
            ),
          ),
          Positioned(
            top: 6,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0041CE),
                        Color(0xFF4897FF),
                        Color(0xFF0041CE),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.product.title,
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Stack(
            children: [
              if (widget.product.id == 'ouro')
                Positioned(
                  top: 2,
                  right: 1,
                  child: Image.asset(
                    'assets/images/MaisVendidov2.png',
                    width: 65,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCardContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 45),
                Text(
                  widget.product.description,
                  style: const TextStyle(
                    fontSize: 18,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width < 380 ? 10 : 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (String line in widget.product.features)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: widget.product.id == 'ouro'
                                          ? Colors.blue
                                          : Colors.green,
                                      size: MediaQuery.of(context).size.width <
                                              380
                                          ? 13
                                          : 16,
                                    ),
                                    // const SizedBox(width: 3.0),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context).size.width < 380 ? 13 : 18,
                                          color: const Color.fromARGB(255, 44, 44, 44),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
        (!kIsWeb && Platform.isIOS)
            ? RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text:
                      'Ao tocar em Compre Já, a cobrança será realizada e sua assinatura será renovada automaticamente pelo mesmo preço e duração do pacote até que você efetue o cancelamento nas configurações da App Store e concorde com nossos ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: 'Termos',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          launchUrl(Uri.parse(
                              'https://fiscojur.com.br/politica-de-privacidade/'));
                        },
                    ),
                    const TextSpan(
                      text: '.',
                    ),
                  ],
                ),
              )
            : Container(),
        const SizedBox(height: 5),
        Center(
          child: Text(
            widget.product.price,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 380 ? 18 : 24,
              color: const Color(0xFF025CE2),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 70.0),
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0041CE),
                    Color.fromARGB(255, 72, 151, 255),
                    Color(0xFF0041CE),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () async {
                  _handlePayment(widget.product);
                },
                child: Container(
                  height: 40,
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                    minWidth: 100,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : widget.buttonWidget,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}
