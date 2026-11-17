import 'entrada.dart';

enum Veredito { empreender, investir, indiferente }

/// MODEL: tudo o que a análise calcula. A View só lê, nunca calcula.
class Resultado {
  const Resultado({
    required this.entrada,
    required this.tma,
    required this.vplNaTma,
    required this.tir,
    required this.tirm,
    required this.payback,
    required this.paybackDescontado,
    required this.indiceLucratividade,
    required this.montanteInvestindo,
    required this.montanteEmpreendendo,
    required this.acumuladoComPremio,
    required this.acumuladoSemPremio,
    required this.veredito,
    required this.avisos,
  });

  /// Entrada usada neste cálculo (garante que tela e resultado combinam).
  final Entrada entrada;
  final double tma;
  final double vplNaTma;
  final double? tir;
  final double? tirm;
  final double? payback;
  final double? paybackDescontado;
  final double? indiceLucratividade;

  /// Capital aplicado na taxa livre de risco até o fim do horizonte.
  final double montanteInvestindo;

  /// Lucros reinvestidos na taxa livre de risco + valor residual.
  final double montanteEmpreendendo;

  /// Fluxo acumulado descontado à TMA (com prêmio) e à taxa livre de risco.
  /// Quando a linha cruza o zero, o investimento foi recuperado.
  final List<double> acumuladoComPremio;
  final List<double> acumuladoSemPremio;

  final Veredito veredito;
  final List<String> avisos;

  /// Sem prêmio de risco: diferença = VPL × (1 + taxaLivreDeRisco)^anos.
  double get diferencaDeMontantes => montanteEmpreendendo - montanteInvestindo;
}
