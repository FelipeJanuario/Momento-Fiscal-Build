import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/simple_plan_card.dart';
import 'package:momentofiscal/core/models/plan_stripe.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/core/models/subscription.dart';
import 'package:momentofiscal/core/services/billing/in_app_purchase_service.dart';
import 'package:momentofiscal/core/services/billing/stripe_service.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Habilita drag com mouse no Web (o padrão do Flutter Web só suporta touch)
class _WebScrollBehavior extends MaterialScrollBehavior {
  const _WebScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

/// Page to display and manage subscription plans
/// WEB-ONLY: All purchases now via Stripe (no mobile app stores)
class VerifyPlansPage extends StatefulWidget {
  /// Quando true, inclui o Plano Free (trial 7 dias) na listagem.
  final bool showFreePlan;
  const VerifyPlansPage({super.key, this.showFreePlan = false});

  @override
  State<VerifyPlansPage> createState() => _VerifyPlansPageState();
}

class _VerifyPlansPageState extends State<VerifyPlansPage> {
  PageController controller = PageController(viewportFraction: 0.85);
  double _lastViewportFraction = 0.85;
  List<PurchasableProduct> products = [];
  List<PlanStripe> plans = [];
  List<Subscription> subscriptions = [];
  bool isLoading = true;
  String? iosSubscription;
  String? statusFree;
  SweepGradient backgroundGradient = const SweepGradient(
    colors: [
      Color(0xFF1A48DD),
      Color(0xB3B30EFF),
      Color(0xFF056ABD),
      Color(0xFF023A5F),
      Color(0xB3A12EE4),
      Color(0xFF1A48DD),
    ],
    center: Alignment.center,
    startAngle: 0.0,
    endAngle: 5.12,
  );

  double _calculateViewportFraction(double width) {
    if (width > 1200) return 0.30;
    if (width > 800) return 0.45;
    if (width > 600) return 0.65;
    return 0.85;
  }

  @override
  void initState() {
    super.initState();
    // Limpa cache para garantir que features/descrições sejam recarregadas
    InAppPurchaseService.instance.products = [];
    loadPlansProducts(showFreePlan: widget.showFreePlan);
    controller.addListener(_onPageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final newFraction = _calculateViewportFraction(screenWidth);
    if (newFraction != _lastViewportFraction) {
      _lastViewportFraction = newFraction;
      final currentPage = controller.hasClients ? controller.page?.round() ?? 0 : 0;
      controller.removeListener(_onPageChanged);
      controller.dispose();
      controller = PageController(
        viewportFraction: newFraction,
        initialPage: currentPage,
      );
      controller.addListener(_onPageChanged);
    }
  }

  void _onPageChanged() {
    if (!controller.hasClients) return;
    int currentPage = controller.page!.round();
    if (currentPage < products.length) {
      final titleLower = products[currentPage].title.toLowerCase();
      if (titleLower.contains("bronze")) {
        setState(() {
          backgroundGradient = const SweepGradient(
            colors: [
              Color.fromARGB(255, 165, 104, 55),
              Color.fromARGB(255, 241, 184, 146),
              Color.fromARGB(255, 140, 85, 40),
              Color.fromARGB(255, 241, 184, 146),
              Color.fromARGB(255, 165, 104, 55),
              Color.fromARGB(255, 241, 184, 146),
              Color.fromARGB(255, 165, 104, 55),
            ],
            center: Alignment.center,
            startAngle: 0.0,
            endAngle: 5.12,
          );
        });
      } else if (titleLower.contains("prata")) {
        setState(() {
          backgroundGradient = const SweepGradient(
            colors: [
              Color(0xFFC8C8C8),
              Color(0xFF5E5E5E),
              Color(0xF9FFFFFF),
              Color(0xFF575757),
              Color(0xF9FFFFFF),
              Color(0xFF575757),
              Color(0xF9FFFFFF),
              Color(0xFF575757),
              Color(0xFFC8C8C8),
            ],
            center: Alignment.center,
            startAngle: 0.0,
            endAngle: 5.12,
          );
        });
      } else if (titleLower.contains("ouro")) {
        setState(() {
          backgroundGradient = const SweepGradient(
            colors: [
              Color(0xFFB98F02),
              Color(0xFFFAEEB8),
              Color(0xFFE3BC11),
              Color(0xFFB38900),
              Color(0xFFFAEEB8),
              Color(0xFFB98F02),
            ],
            center: Alignment.center,
            startAngle: 0.0,
            endAngle: 5.12,
          );
        });
      } else {
        setState(() {
          backgroundGradient = const SweepGradient(
            colors: [
              Color(0xFF1A48DD),
              Color(0xB3B30EFF),
              Color(0xFF056ABD),
              Color(0xFF023A5F),
              Color(0xB3A12EE4),
              Color(0xFF1A48DD),
            ],
            center: Alignment.center,
            startAngle: 0.0,
            endAngle: 5.12,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onPageChanged);
    controller.dispose();
    products = [];
    plans = [];
    subscriptions = [];
    super.dispose();
  }

  /// Cria um produto virtual para o Plano Free (trial de 7 dias).
  PurchasableProduct _freePlanProduct() {
    return PurchasableProduct(
      ProductDetails(
        id: 'free',
        title: 'Plano Free',
        description: 'Experimente grátis por 7 dias',
        price: 'R\$ 0,00',
        rawPrice: 0.0,
        currencyCode: 'BRL',
      ),
      features: [
        'Localizar Devedores próximos',
        'Consultas básicas de CPF/CNPJ',
        'Acesso por 7 dias',
        'Sem necessidade de cartão',
      ],
    );
  }

  Future<void> loadPlansProducts({bool showFreePlan = false}) async {
    try {
      // WEB-ONLY: Fetch products from Stripe via backend
      final fetchedProducts = await InAppPurchaseService.instance.getProducts().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Logger.log('Timeout ao carregar produtos', level: LoggerLevel.error);
          return <PurchasableProduct>[];
        },
      );

      if (mounted) {
        setState(() {
          products = [
            if (showFreePlan) _freePlanProduct(),
            ...fetchedProducts,
          ];
          isLoading = false;
        });
      }
    } on StripeAuthException {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
      }
    } catch (e) {
      Logger.log('Erro ao carregar planos e produtos: $e', level: LoggerLevel.error, error: e);
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatPrice(String unitAmountDecimal) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final value = int.parse(unitAmountDecimal) / 100;
    return formatter.format(value);
  }

  Color getButtonColor(String productId) {
    for (final plan in plans) {
      if (plan.product == productId) {
        return colorSecundary;
      }
    }
    return const Color(0xFF025CE2);
  }

  Widget getButtonWidget(PurchasableProduct productStripe) {
    return const Text(
      'Assinar Agora',
      style: TextStyle(color: Colors.white),
    );
  }

  bool getButtonisValid(String productId) {
    // Always enable for now - will check on backend
    return true;
  }

  Widget _buildDesktopPlans(double cardWidth) {
    return LayoutBuilder(
      builder: (ctx, cst) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: cst.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: products.map((product) {
              final buttonColor = getButtonColor(product.id);
              final buttonWidget = getButtonWidget(product);
              final isPlanButton = getButtonisValid(product.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: SizedBox(
                  width: cardWidth,
                  child: SimplePlanCard(
                    product: product,
                    buttonColor: buttonColor,
                    buttonWidget: buttonWidget,
                    isEnabled: isPlanButton,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobilePlans() {
    return ScrollConfiguration(
      behavior: const _WebScrollBehavior(),
      child: PageView.builder(
        controller: controller,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final buttonColor = getButtonColor(product.id);
          final buttonWidget = getButtonWidget(product);
          final isPlanButton = getButtonisValid(product.id);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
            child: SimplePlanCard(
              product: product,
              buttonColor: buttonColor,
              buttonWidget: buttonWidget,
              isEnabled: isPlanButton,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Selecionando Plano',
          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: backgroundGradient,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final cardWidth = products.isNotEmpty
                ? (screenWidth / (products.length + 1)).clamp(200.0, 300.0)
                : 280.0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    height: 50,
                    child: Image.asset(
                      'assets/images/momentofiscalbrancov2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : screenWidth > 800
                          ? _buildDesktopPlans(cardWidth)
                          : _buildMobilePlans(),
                ),
                if (!isLoading && products.isNotEmpty && screenWidth <= 800)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SmoothPageIndicator(
                      controller: controller,
                      count: products.length,
                      effect: const WormEffect(
                        dotHeight: 16,
                        dotWidth: 16,
                        type: WormType.thinUnderground,
                        dotColor: Colors.white,
                        activeDotColor: colorSecundary,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
