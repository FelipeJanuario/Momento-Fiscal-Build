import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/core/services/billing/stripe_service.dart';
import 'package:momentofiscal/core/utilities/logger.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';
import 'package:momentofiscal/pages/dashboard/dashboad_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final _storage = const FlutterSecureStorage();

  Future<void> _handleCheckout() async {
    if (!widget.isEnabled || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user email for Stripe checkout
      String? userEmail = await _storage.read(key: 'email');
      
      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('Email do usuário não encontrado');
      }

      // For free plan, no payment needed
      if (widget.product.isFree) {
        await _handleFreePlan();
        return;
      }

      // Create Stripe checkout session
      await StripeService().createCheckoutSession(
        priceId: widget.product.id,
        customerEmail: userEmail,
      );

      // TODO: Integrate Stripe Payment Element here
      // For now, show success message
      if (mounted) {
        _showSuccessDialog();
      }

    } catch (e) {
      Logger.log('Error during checkout: $e', level: LoggerLevel.error, error: e);
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
    // Free plan logic here
    Logger.log('Activating free plan');
    await _storage.write(key: 'subscription', value: 'free');
    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
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
                Navigator.of(context).pop();
                // Navigate to dashboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboadPage()),
                );
              },
              child: const Text('OK', style: TextStyle(color: colorSecundary)),
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
          content: Text(
            'Não foi possível processar a assinatura. Tente novamente.',
            style: const TextStyle(fontSize: 16),
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
