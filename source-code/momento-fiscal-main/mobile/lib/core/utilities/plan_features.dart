/// Hierarquia de planos e controle de acesso por funcionalidade.
///
/// Planos (do menor para o maior):
///   free < bronze < prata < ouro
///
/// Funcionalidades liberadas por plano mínimo:
///   free   → Localize Devedores
///   bronze → Consultar Devedores, Consultar Processos
///   prata  → Consulta por Município, Análise Processual
///   ouro   → Gestão de Consultoria, Consultoria personalizada
class PlanFeatures {
  PlanFeatures._();

  static const String free = 'free';
  static const String bronze = 'bronze';
  static const String prata = 'prata';
  static const String ouro = 'ouro';

  /// Índice numérico de cada plano para comparação hierárquica.
  static const Map<String, int> _planLevel = {
    free: 0,
    bronze: 1,
    prata: 2,
    ouro: 3,
  };

  /// Retorna `true` se o [currentPlan] do usuário atende ao [requiredPlan].
  /// Admin sempre retorna `true`.
  static bool hasAccess({
    required String? currentPlan,
    required String requiredPlan,
    String? userRole,
  }) {
    if (userRole == 'admin') return true;
    if (currentPlan == null) return false;

    final currentLevel = _planLevel[currentPlan.toLowerCase()] ?? -1;
    final requiredLevel = _planLevel[requiredPlan.toLowerCase()] ?? 999;

    return currentLevel >= requiredLevel;
  }

  /// Nome amigável do plano.
  static String displayName(String? planId) {
    switch (planId?.toLowerCase()) {
      case 'free':
        return 'Free';
      case 'bronze':
        return 'Bronze';
      case 'prata':
        return 'Prata';
      case 'ouro':
        return 'Ouro';
      default:
        return 'Nenhum';
    }
  }
}
