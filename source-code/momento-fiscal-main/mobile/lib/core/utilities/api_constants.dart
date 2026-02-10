class ApiConstants {
  // Modo desenvolvimento: controla se usa localhost ou produção
  static const bool devMode = bool.fromEnvironment('DEV_MODE', defaultValue: false);
  
  // URL base da API
  // DEV_MODE=true  → http://localhost:3000
  // DEV_MODE=false → https://momentofiscal.com.br (produção)
  static String url = devMode ? 'http://localhost:3000' : 'https://momentofiscal.com.br';
  static String baseUrl = '$url/api/v1';
  
  // Debug: imprime configuração ao inicializar
  static void printConfig() {
    print('🔵 [ApiConstants] DEV_MODE: $devMode');
    print('🔵 [ApiConstants] API URL: $url');
    print('🔵 [ApiConstants] Base URL: $baseUrl');
  }

  static String merchantIdentifier = "merchant.br.com.momentofiscal";

  static String entitlementID = "plans";

  static String footerText =
      """ A purchase will be applied to your account upon confirmation of the amount selected.""";

  static String appleKey = "appl_WVDIstyRxuOyjCsrZtXThwZtenW";
}
