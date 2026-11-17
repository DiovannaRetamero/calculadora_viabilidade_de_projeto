/// MODEL: dados de entrada da calculadora (imutável).
/// Taxas em decimal (10% = 0.10) e valores em reais. Os padrões são o exemplo
/// usado nos testes: R$ 100 mil, 5 anos, lucro de R$ 25 mil/ano.
class Entrada {
  const Entrada({
    this.capitalInicial = 100000,
    this.anos = 5,
    this.taxaLivreDeRisco = 0.10,
    this.premioDeRisco = 0.10,
    this.faturamentoAnual = 150000,
    this.despesasAnuais = 100000,
    this.proLaboreAnual = 25000,
    this.valorResidual = 50000,
  });

  final double capitalInicial;
  final int anos;

  /// Rendimento da alternativa segura (Selic/CDI líquido de IR, por exemplo).
  final double taxaLivreDeRisco;

  /// Retorno extra exigido para compensar o risco e o esforço de empreender.
  final double premioDeRisco;

  final double faturamentoAnual;

  /// Custos, despesas e impostos do negócio, por ano.
  final double despesasAnuais;

  /// Custo de oportunidade do seu trabalho (o que ganharia no mercado).
  final double proLaboreAnual;

  /// Quanto o negócio vale (ou o que se recupera) no fim do horizonte.
  final double valorResidual;

  /// Taxa Mínima de Atratividade: livre de risco + prêmio.
  double get tma => taxaLivreDeRisco + premioDeRisco;

  double get lucroAnual => faturamentoAnual - despesasAnuais - proLaboreAnual;

  /// Índice 0 = hoje (−capital); índice k = fim do ano k.
  List<double> get fluxoDoNegocio => [
        -capitalInicial,
        for (var t = 1; t <= anos; t++)
          lucroAnual + (t == anos ? valorResidual : 0.0),
      ];

  Entrada copyWith({
    double? capitalInicial,
    int? anos,
    double? taxaLivreDeRisco,
    double? premioDeRisco,
    double? faturamentoAnual,
    double? despesasAnuais,
    double? proLaboreAnual,
    double? valorResidual,
  }) =>
      Entrada(
        capitalInicial: capitalInicial ?? this.capitalInicial,
        anos: anos ?? this.anos,
        taxaLivreDeRisco: taxaLivreDeRisco ?? this.taxaLivreDeRisco,
        premioDeRisco: premioDeRisco ?? this.premioDeRisco,
        faturamentoAnual: faturamentoAnual ?? this.faturamentoAnual,
        despesasAnuais: despesasAnuais ?? this.despesasAnuais,
        proLaboreAnual: proLaboreAnual ?? this.proLaboreAnual,
        valorResidual: valorResidual ?? this.valorResidual,
      );
}
