import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:momentofiscal/core/utilities/api_constants.dart';
import 'package:http/http.dart' as http;

FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

class InvitationRailsService {
  Future createInvation({required String email}) async {
    String url = '${ApiConstants.baseUrl}/invitations';

    String? token = await _secureStorage.read(key: 'token');

    Map<String, dynamic> body = {
      "invitation": {"email": email}
    };

    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    var response = await http.post(Uri.parse(url),
        body: json.encode(body), headers: headers);

    return response;
  }

  // Verifica se existe um convite para o email
  Future<http.Response> checkInvitation(String email) async {
    final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/invitations/check?email=$email'));

    return response;
  }

  // Atualiza o status do convite para "accepted"
  Future<http.Response> updateInvitationStatus(
      String email, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/invitations/update_status'),
      body: jsonEncode({'email': email, 'status': status}),
      headers: {'Content-Type': 'application/json'},
    );
    return response;
  }
}
