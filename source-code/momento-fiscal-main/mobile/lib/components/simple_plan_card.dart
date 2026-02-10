import 'package:flutter/material.dart';
import 'package:momentofiscal/core/models/purchasable_product.dart';
import 'package:momentofiscal/components/stripe_checkout_button.dart';
import 'package:momentofiscal/core/utilities/styles_constants.dart';

/// Simplified plan card for web-only Stripe subscriptions
class SimplePlanCard extends StatelessWidget {
  final PurchasableProduct product;
  final Color buttonColor;
  final Widget buttonWidget;
  final bool isEnabled;

  const SimplePlanCard({
    super.key,
    required this.product,
    required this.buttonColor,
    required this.buttonWidget,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [buttonColor.withOpacity(0.8), buttonColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                product.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Plan description
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          // Features list
          ...product.features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: buttonColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 32),

          // Price
          Center(
            child: Text(
              product.price,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: buttonColor,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Checkout button
          StripeCheckoutButton(
            product: product,
            buttonColor: buttonColor,
            buttonWidget: buttonWidget,
            isEnabled: isEnabled,
          ),
        ],
      ),
    );
  }
}
