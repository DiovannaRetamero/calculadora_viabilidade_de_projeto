import 'package:flutter/foundation.dart';

import '../models/analise_viabilidade.dart';
import '../models/entrada.dart';
import '../models/resultado.dart';
import '../utils/formatadores.dart';

enum Campo { capital, anos, taxa, faturamento, despesas, proLabore, valorResidual }

/// CONTROLLER: faz a ponte entre View e Model.
/// - recebe os eventos da tela (texto digitado, slider);
/// - converte e valida os valores, atualizando a [Entrada];
/// - pede o cálculo ao Model e avisa a View com notifyListeners().
class CalculadoraController extends ChangeNotifier {
  CalculadoraController({AnaliseViabilidade analise = const AnaliseViabilidade()})
      : _analise = analise {
    _recalcular();
  }

  final AnaliseViabilidade _analise;
  final Map<Campo, String> _erros = {};
  Entrada _entrada = const Entrada();
  Resultado? _resultado;

  Entrada get entrada => _entrada;

  /// null enquanto houver campo com erro de validação.
  Resultado? get resultado => _resultado;

  String? erroDe(Campo campo) => _erros[campo];

  /// [texto] é o que está no campo, no formato brasileiro (ex.: "10.000,00").
  void atualizarCampo(Campo campo, String texto) {
    final v = lerNumeroBR(texto);
    _entrada = switch (campo) {
      Campo.capital => _entrada.copyWith(capitalInicial: v),
      Campo.anos => _entrada.copyWith(anos: v.round()),
      Campo.taxa => _entrada.copyWith(taxaLivreDeRisco: v / 100),
      Campo.faturamento => _entrada.copyWith(faturamentoAnual: v),
      Campo.despesas => _entrada.copyWith(despesasAnuais: v),
      Campo.proLabore => _entrada.copyWith(proLaboreAnual: v),
      Campo.valorResidual => _entrada.copyWith(valorResidual: v),
    };
    _recalcular();
  }

  /// Prêmio de risco em pontos percentuais (10 = 10 p.p.).
  void atualizarPremio(double pontosPercentuais) {
    _entrada = _entrada.copyWith(premioDeRisco: pontosPercentuais / 100);
    _recalcular();
  }

  void _recalcular() {
    _erros.clear();
    if (_entrada.capitalInicial <= 0) {
      _erros[Campo.capital] = 'Informe um valor maior que zero';
    }
    if (_entrada.anos < 1 || _entrada.anos > 40) {
      _erros[Campo.anos] = 'Use de 1 a 40 anos';
    }
    if (_entrada.taxaLivreDeRisco < 0 || _entrada.taxaLivreDeRisco > 1) {
      _erros[Campo.taxa] = 'Use de 0% a 100%';
    }
    _resultado = _erros.isEmpty ? _analise.avaliar(_entrada) : null;
    notifyListeners();
  }
}
