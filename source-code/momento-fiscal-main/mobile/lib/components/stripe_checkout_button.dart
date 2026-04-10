import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/core/services/billing/stripe_service.dart';
import 'package:momentofiscal/core/services/freePlanUsage/free_plans_usages_rails_servide.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/services/storage/storage_service.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:momentofiscal/pages/login/auth_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Stripe checkout button for web-based subscriptions
/// Replaces complex app store purchase logic
class StripeCheckoutButton extends StatefulWidget {
  final PurchasableProduct product;
  final Color buttonColor;
  final Widget buttonWidget;
  final bool isEnabled;

  const StripeCheckoutButton({
    super.key,
    required this.product,
    required this.buttonColor,
    required this.buttonWidget,
    required this.isEnabled,
  });

  @override
  State<StripeCheckoutButton> createState() => _StripeCheckoutButtonState();
}

class _StripeCheckoutButtonState extends State<StripeCheckoutButton> {
  bool _isLoading = false;
  String? _subscriptionIdBeforeCheckout;
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  /// Inicia o listener de deep links para capturar o retorno do Stripe Checkout.
  /// Chamado somente quando o checkout é aberto no browser.
  void _startDeepLinkListener() {
    _deepLinkSub?.cancel();
    final appLinks = AppLinks();
    _deepLinkSub = appLinks.uriLinkStream.listen((Uri uri) {
      if (uri.scheme != 'momentofiscal') return;

      _deepLinkSub?.cancel();
      _deepLinkSub = null;

      if (uri.host == 'payment' && uri.path == '/success') {
        _verifySubscriptionAfterCheckout();
      } else if (uri.host == 'payment' && uri.path == '/cancel') {
        // Usuário cancelou no Stripe — nada a fazer, apenas limpar estado
        _subscriptionIdBeforeCheckout = null;
      }
    });
  }

  Future<void> _verifySubscriptionAfterCheckout() async {
    if (!mounted) return;

    setState(() { _isLoading = true; });

    try {
      // Aguardar um pouco para o Stripe processar
      await Future.delayed(const Duration(seconds: 2));

      final currentSub = await StripeService().getCurrentSubscription();
      if (currentSub != null && mounted) {
        final newSubId = currentSub['id'] as String?;
        // Só reconhece pagamento se a assinatura é nova (ID diferente ou inexistente antes)
        if (newSubId != _subscriptionIdBeforeCheckout) {
          final productName = currentSub['items']?['data']?[0]?['price']?['product'] ?? '';
          await storage.write(key: 'subscriptionPlatform', value: 'stripe');
          await storage.write(key: 'planLevel', value: productName);
          _showSuccessDialog();
          return;
        }
      }

      // Sem assinatura nova — usuário voltou sem pagar ou pagamento em processamento
      if (mounted) {
        _showPendingDialog();
      }
    } catch (e) {
      Logger.log('Error verifying subscription: $e', level: LoggerLevel.error, error: e);
    } finally {
      _subscriptionIdBeforeCheckout = null;
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _handleCheckout() async {
    if (!widget.isEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user email for Stripe checkout
      String? userEmail = await storage.read(key: 'email');
      
      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('Email do usuário não encontrado');
      }

      // For free plan, no payment needed
      if (widget.product.isFree) {
        await _handleFreePlan();
        return;
      }

      // Capturar assinatura existente antes de abrir o checkout
      // para evitar falso positivo ao retornar sem ter pago
      final existingSub = await StripeService().getCurrentSubscription();
      _subscriptionIdBeforeCheckout = existingSub?['id'] as String?;

      // Create Stripe checkout session and open hosted page
      // No mobile, usar deep link scheme para redirecionar de volta ao app
      final String? successUrl;
      final String? cancelUrl;
      if (kIsWeb) {
        successUrl = Uri.base.toString();
        cancelUrl = null;
      } else {
        successUrl = 'momentofiscal://payment/success?session_id={CHECKOUT_SESSION_ID}';
        cancelUrl = 'momentofiscal://payment/cancel';
      }

      final checkoutUrl = await StripeService().createCheckoutSession(
        priceId: widget.product.id,
        customerEmail: userEmail,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      // Iniciar listener de deep link antes de abrir o browser
      if (!kIsWeb) {
        _startDeepLinkListener();
      }

      // Open Stripe hosted checkout page in browser
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _deepLinkSub?.cancel();
        _deepLinkSub = null;
        throw Exception('Não foi possível abrir a página de pagamento');
      }

    } on StripeAuthException {
      _deepLinkSub?.cancel();
      _deepLinkSub = null;
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (_) => false,
        );
      }
    } catch (e) {
      Logger.log('Error during checkout: $e', level: LoggerLevel.error, error: e);
      _deepLinkSub?.cancel();
      _deepLinkSub = null;
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFreePlan() async {
    try {
      String? userId = await storage.read(key: 'id');

      if (userId == null || userId.isEmpty) {
        throw Exception('Usuário não identificado');
      }

      // Verificar se já usou plano free
      final responseStatus = await FreePlansUsagesRailsService()
          .getFreePlansUsages(userId: userId)
          .timeout(const Duration(seconds: 15));

      if (responseStatus != null) {
        final decoded = json.decode(responseStatus);
        final freePlanUsages = decoded['free_plan_usages'] as List? ?? [];
        final expiredIds = decoded['expired_plan_ids'] as List? ?? [];

        // Plano free já expirado
        if (expiredIds.isNotEmpty) {
          if (mounted) {
            _showFreePlanExpiredDialog();
          }
          return;
        }

        // Já possui plano free ativo
        if (freePlanUsages.isNotEmpty && freePlanUsages[0]['status'] == 'active') {
          // Já está usando free — gravar no storage e ir ao dashboard
          await storage.write(key: 'subscriptionPlatform', value: 'free');
          await storage.write(key: 'statusFree', value: 'active');
          await storage.write(key: 'planLevel', value: 'free');
          if (mounted) _showFreePlanAlreadyActiveDialog();
          return;
        }
      }

      // Registrar plano free no backend
      final responseFree = await FreePlansUsagesRailsService()
          .createFreePlanUsage(userId: userId)
          .timeout(const Duration(seconds: 15));

      final responseBody = json.decode(responseFree.body);
      final message = responseBody['message'] ?? '';

      if (message == 'Plano gratuito já utilizado') {
        if (mounted) _showFreePlanAlreadyUsedDialog();
        return;
      }

      // Sucesso — gravar no storage
      await storage.write(key: 'subscriptionPlatform', value: 'free');
      await storage.write(key: 'statusFree', value: 'active');
      await storage.write(key: 'planLevel', value: 'free');

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      Logger.log('Error activating free plan: $e', level: LoggerLevel.error, error: e);
      if (mounted) {
        _showErrorDialog('Erro ao ativar o plano gratuito. Tente novamente.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: colorSecundary, size: 32),
              SizedBox(width: 12),
              Text('Sucesso!'),
            ],
          ),
          content: Text(
            'Assinatura do ${widget.product.title} ativada com sucesso!',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const DashboadPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK', style: TextStyle(color: colorSecundary)),
            ),
          ],
        );
      },
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top, color: Colors.orange, size: 32),
              SizedBox(width: 12),
              Expanded(child: Text('Processando pagamento')),
            ],
          ),
          content: const Text(
            'Seu pagamento está sendo processado. Caso já tenha concluído, aguarde alguns instantes e volte à tela de planos para verificar.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: colorSecundary)),
            ),
          ],
        );
      },
    );
  }

  void _showFreePlanExpiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Plano Expirado'),
          content: const Text(
            'Seu plano gratuito já expirou. É necessário assinar um plano pago para continuar.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi', style: TextStyle(color: colorSecundary)),
            ),
          ],
        );
      },
    );
  }

  void _showFreePlanAlreadyActiveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Plano Free Ativo'),
          content: const Text(
            'Você já possui o Plano Free ativo com duração de 3 dias.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const DashboadPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Ir ao Dashboard', style: TextStyle(color: colorSecundary)),
            ),
          ],
        );
      },
    );
  }

  void _showFreePlanAlreadyUsedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Plano Free já utilizado'),
          content: const Text(
            'Você já utilizou o período gratuito de 3 dias. Selecione um plano pago para continuar.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi', style: TextStyle(color: colorSecundary)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Erro'),
            ],
          ),
          content: const Text(
            'Não foi possível processar a assinatura. Tente novamente.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: colorSecundary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isEnabled ? _handleCheckout : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.buttonColor,
        disabledBackgroundColor: Colors.grey,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : widget.buttonWidget,
    );
  }
}
