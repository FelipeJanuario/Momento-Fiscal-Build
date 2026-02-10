import 'dart:convert';

import 'package:momentofiscal/core/services/api/api_request_service.dart';
import 'package:momentofiscal/core/utilities/logger.dart';

class GoogleService {
  GoogleService._();
  static final GoogleService instance = GoogleService._();

  /// Fetches available subscriptions from Google Play
  /// 
  /// Returns a Map containing the subscription data from Google Play API
  /// Throws an exception if the request fails
  Future<Map<String, dynamic>> getAvailableSubscriptions() async {
    try {
      final response = await ApiRequestService.instance.get('google/available_subscriptions');

      return json.decode(response) as Map<String, dynamic>;
    } catch (e) {
      Logger.log(
        'Error fetching available subscriptions',
        error: e,
      );
      rethrow;
    }
  }
}
