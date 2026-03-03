import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:momentofiscal/components/simple_plan_card.dart';
import 'package:momentofiscal/core/models/plan_stripe.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/core/models/subscription.dart';
import 'package:momentofiscal/core/services/billing/in_app_purchase_service.dart';
import 'package:momentofiscal/core/services/billing/stripe_service.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Page to display and manage subscription plans
/// WEB-ONLY: All purchases now via Stripe (no mobile app stores)
class VerifyPlansPage extends StatefulWidget {
  const VerifyPlansPage({super.key});

  @override
  State<VerifyPlansPage> createState() => _VerifyPlansPageState();
}

class _VerifyPlansPageState extends State<VerifyPlansPage> {
  final PageController controller = PageController();
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

  @override
  void initState() {
    super.initState();
    loadPlansProducts();

    controller.addListener(() {
      int currentPage = controller.page!.round();
      if (currentPage < products.length) {
        if (products[currentPage].id.toLowerCase() == "bronze") {
          setState(() {
            backgroundGradient = const SweepGradient(
              colors: [
                Color.fromARGB(255, 165, 104, 55), // Bronze avermelhado
                Color.fromARGB(255, 241, 184, 146), // Dourado avermelhado
                Color.fromARGB(255, 140, 85, 40), // Bronze profundo avermelhado
                Color.fromARGB(255, 241, 184, 146), // Dourado avermelhado
                Color.fromARGB(255, 165, 104, 55), // Bronze avermelhado
                Color.fromARGB(255, 241, 184, 146), // Dourado avermelhado
                Color.fromARGB(255, 165, 104, 55), // Bronze avermelhado
              ],
              center: Alignment.center,
              startAngle: 0.0,
              endAngle: 5.12,
            );
          });
        } else if (products[currentPage].id.toLowerCase() == "prata") {
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
        } else if (products[currentPage].id.toLowerCase() == "ouro") {
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
    });
  }

  @override
  void dispose() {
    super.dispose();
    products = [];
    plans = [];
    subscriptions = [];
    controller.dispose();
  }

  Future<void> loadPlansProducts() async {
    try {
      // WEB-ONLY: Fetch products from Stripe via backend
      final newProducts = await InAppPurchaseService.instance.getProducts().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          Logger.log('Timeout ao carregar produtos', level: LoggerLevel.error);
          return <PurchasableProduct>[];
        },
      );

      // Fetch active subscriptions from Stripe
      final activeSubscriptions = await StripeService().getActiveSubscriptions();
      
      // Store active product IDs for plan checking
      final activeProductIds = activeSubscriptions
          .map((sub) => sub['items']['data'][0]['price']['product'] as String)
          .toSet();

      if (mounted) {
        setState(() {
          products = newProducts;
          isLoading = false;
        });
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
    // Check if user already has this plan active
    // (plans list is not used anymore - checking via Stripe API)
    if (false) {
      return const Wrap(
        children: [
          Text(
            'Plano já obtido',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(width: 5),
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.white,
            size: 20,
          )
        ],
      );
    }

    return const Text(
      'Assinar Agora',
      style: TextStyle(color: Colors.white),
    );
  }

  bool getButtonisValid(String productId) {
    // Always enable for now - will check on backend
    return true;
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
        child: Column(
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
                  : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: PageView.builder(
                        controller: controller,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final Color buttonColor = getButtonColor(product.id);
                          final Widget buttonWidget = getButtonWidget(product);
                          final bool isPlanButton =
                              getButtonisValid(product.id);

                          return Padding(
                            padding: const EdgeInsets.all(25),
                            child: SimplePlanCard(
                              product: product,
                              buttonColor: buttonColor,
                              buttonWidget: buttonWidget,
                              isEnabled: isPlanButton,
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (!isLoading && products.isNotEmpty)
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
        ),
      ),
    );
  }
}
