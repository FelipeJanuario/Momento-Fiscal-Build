import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:momentofiscal/components/logout_card.dart';
import 'package:momentofiscal/components/on_selected_popup.dart';
import 'package:momentofiscal/core/services/freePlanUsage/free_plans_usages_rails_servide.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/consulting/clients/consulting_page.dart';
import 'package:momentofiscal/pages/consulting/management/consulting_management_page.dart';
import 'package:momentofiscal/pages/institution/institution_page.dart';
import 'package:momentofiscal/pages/location/authorized_location_page.dart';
import 'package:momentofiscal/pages/location/search_by_location_page.dart';
import 'package:momentofiscal/pages/location/search_by_location_osm_page.dart';
import 'package:momentofiscal/pages/plans/verify_plans_page.dart';
import 'package:momentofiscal/pages/proposal/my_proposal_client_page.dart';
import 'package:momentofiscal/core/services/auth/auth_rails_service.dart';
import 'package:momentofiscal/pages/search/cnpj_cpf_page.dart';
import 'package:momentofiscal/pages/search/process_search_page.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/services/billing/in_app_purchase_service.dart';

class DashboadPage extends StatefulWidget {
  const DashboadPage({super.key});

  @override
  State<DashboadPage> createState() => _DashboadPageState();
}

class _DashboadPageState extends State<DashboadPage> {
  LocationPermission? permission;
  String? userRole;
  String? id;
  bool isSubscribed = false;
  String? activePlan;
  bool isCustomerStatusUpdated = false;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    // Garantir que o _currentUser seja carregado do cache (importante para Web após refresh)
    await AuthRailsService().loadUserFromCache();
    
    await checkLocationPermission(); // Carrega id e userRole
    await checkIsSubscription(); // Agora id já está carregado
  }

  Future updateCustomerStatus() async {
    if (isCustomerStatusUpdated) return;
    if (id == null) return; // Proteção contra id null

    final customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.active.isEmpty && !isCustomerStatusUpdated) {
      isCustomerStatusUpdated = true;

      AuthRailsService()
          .patchMapUser(id: id!, updatedFields: {"ios_plan": false});
      await storage.write(key: 'iosPlan', value: "false");
    } else {
      for (var entry in customerInfo.entitlements.active.entries) {
        // ignore: unnecessary_null_comparison
        if (entry.value != null) {
          setState(() {
            activePlan = entry.key;
          });
          await storage.write(key: 'iosSubscription', value: activePlan);
          await storage.write(key: 'subscriptionPlatform', value: 'apple');

          isSubscribed = true;
          break;
        }
      }
    }
  }

  Future checkIsSubscription() async {
    var currentPlatform = await storage.read(key: 'subscriptionPlatform');
    String? iosPlan = await storage.read(key: 'iosPlan');

    // Check if user is admin
    if (userRole == 'admin') {
      return;
    }

    // Proteção contra id null
    if (id == null) return;

    // Check plan status on IOS device
    if (!kIsWeb && Platform.isIOS) {
      var responseFreePlanUsage =
          await FreePlansUsagesRailsService().getFreePlansUsages(userId: id!);

      String statusFree = json
              .decode(responseFreePlanUsage)['free_plan_usages']
              .isNotEmpty
          ? json.decode(responseFreePlanUsage)['free_plan_usages'][0]['status']
          : 'null';

      await storage.write(key: 'statusFree', value: statusFree);

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        updateCustomerStatus();
      });
      await updateCustomerStatus();

      currentPlatform = await storage.read(key: 'subscriptionPlatform');

      var subscriptionActive =
          await InAppPurchaseService.instance.getActiveSubscription();

      // Check if user has an active subscription
      if (subscriptionActive != null) {
        // showDialogForExistingPlan('Android');
        await storage.write(key: 'subscriptionPlatform', value: 'google_play');
        return;
      }

      // Check if user has a free plan
      if (currentPlatform == null &&
          userRole   != 'admin' &&
          iosPlan    == 'false' &&
          statusFree != 'active' &&
          statusFree != 'upgraded') {
        showDialogForSelectPlan();
      }

      return;
    }

    // Check plan status on Android device
    if (!kIsWeb && Platform.isAndroid) {
      if (iosPlan == 'true') {
        await storage.write(key: 'subscriptionPlatform', value: 'apple');
        currentPlatform = await storage.read(key: 'subscriptionPlatform');
        // showDialogForExistingPlan('Apple');
      } else {
        var subscriptionActive =
            await InAppPurchaseService.instance.getActiveSubscription();
        if (subscriptionActive != null) {
          await InAppPurchaseService.instance.getEnabledFeatures();
          await storage.write(key: 'subscriptionPlatform', value: 'google_play');

          currentPlatform = await storage.read(key: 'subscriptionPlatform');

          await Future.delayed(const Duration(seconds: 4));

          var permissionSubscription =
              await InAppPurchaseService.instance.getEnabledFeatures();
          await storage.write(
              key: 'subscription', value: permissionSubscription.toString());
        }
      }
      if (currentPlatform == null && iosPlan == "false" && userRole != 'admin') {
        showDialogForSelectPlan();
      }
    }
    return;
  }

  void showDialogForExistingPlan(String platform) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Plano ativo em outra plataforma"),
          content: Text(
              "Você já possui um plano ativo na plataforma $platform. "
              "Por favor, utilize a mesma plataforma para continuar sua assinatura."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: colorTertiary,
              ),
              child: const Text("Ok", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void showDialogForSelectPlan() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("É preciso selecionar um Plano"),
          content: const Text(
              "Para continuar na aplicação, é necessário selecionar um plano."),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    logoutCard(context);
                  },
                  icon: const Icon(
                    Icons.exit_to_app,
                    color: Colors.red,
                  ),
                  tooltip: 'Sair',
                ),
                const Text(
                  'Sair',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const VerifyPlansPage()),
                      (Route<dynamic> route) => false);
                },
                style: ElevatedButton.styleFrom(
                    elevation: 2,
                    backgroundColor: colorTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 20)),
                child: const Text(
                  "Selecionar Plano",
                  style: TextStyle(color: Colors.white),
                ))
          ],
        );
      },
    );
  }

  Future<void> checkLocationPermission() async {
    id = await storage.read(key: 'id');
    userRole = await storage.read(key: 'role');

    final LocationPermission permissionResult =
        await Geolocator.checkPermission();
    setState(() {
      permission = permissionResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Momento Fiscal'),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [OnSelectedPopup(isDashboardPage: true)],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: Image.asset('assets/images/momentofiscalcolorido.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 15),
              _buildCard(
                title: 'Consultar Devedores',
                subtitle: 'Verifique se um CPF/CNPJ tem dívidas com a União',
                icon: Icons.article,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const CnpjCpfPage()),
                  );
                },
              ),
              _buildCard(
                title: 'Consultar Processos',
                subtitle: 'Busque processos judiciais por número (CNJ)',
                icon: Icons.gavel,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const ProcessSearchPage()),
                  );
                },
              ),
              _buildCard(
                title: 'Localize Devedores',
                subtitle: 'Encontre os maiores devedores próximos a você',
                icon: Icons.location_on,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          permission == LocationPermission.whileInUse
                              ? const SearchByLocationOsmPage() // Nova página OSM (100% gratuita)
                              : const AuthorizedLocation(),
                    ),
                  );
                },
              ),
              if (userRole == 'admin' || userRole == 'consultant') ...[
                _buildCard(
                  title: 'Gestão de Consultoria',
                  subtitle: "Visualize e edite as gestões de consultoria",
                  icon: Icons.view_list_sharp,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ConsultingManagementPage(
                          isConsultant: userRole == 'consultant' ? true : false,
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (userRole == 'admin') ...[
                _buildCard(
                  title: 'Instituições Cadastradas',
                  subtitle:
                      "Visualize e edite as instituições cadastradas no aplicativo",
                  icon: Icons.business,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const InstitutionPage()),
                    );
                  },
                ),
                _buildCard(
                  title: 'Painel de Consultores',
                  subtitle: "Visualize, edite e envie um convite ao consultor",
                  icon: Icons.manage_accounts_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ConsultingPage(
                                typePageRole: 'consultant',
                              )),
                    );
                  },
                ),
                _buildCard(
                  title: 'Painel de Clientes',
                  subtitle: "Visualize, edite ou exclua um cliente",
                  icon: Icons.supervised_user_circle_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ConsultingPage(
                                typePageRole: 'client',
                              )),
                    );
                  },
                ),
              ],
              if (userRole == "client")
                _buildCard(
                  title: 'Minhas Propostas',
                  subtitle: "Acomponhar minhas propostas criadas",
                  icon: Icons.business_center,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const MyProposalClientPage()),
                    );
                  },
                ),
              _buildCard(
                title: 'Planos e Pagamento',
                subtitle: "Visualize e edite seu plano de pagamento",
                icon: Icons.payment,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const VerifyPlansPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required String subtitle,
      required IconData icon,
      required Function()? onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, color: colorPrimaty, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
