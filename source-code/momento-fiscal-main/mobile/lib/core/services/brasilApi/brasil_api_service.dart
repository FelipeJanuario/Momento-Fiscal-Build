import 'package:http/http.dart' as http;

class BrasilApiService {
  Future getCnpj(String cnpj) async {
    var url = 'https://brasilapi.com.br/api/cnpj/v1/$cnpj';

    var response = await http.get(Uri.parse(url));

    return response;
  }
}
