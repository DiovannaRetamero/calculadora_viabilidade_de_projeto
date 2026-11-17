import 'dart:math' as math;

import 'entrada.dart';
import 'resultado.dart';

// MODEL: regras de negócio. Não conhece Flutter nem telas.
// Fluxo de caixa: índice 0 = hoje (negativo), índice k = fim do ano k.

/// Valor Presente Líquido: soma dos fluxos descontados à [taxa].
double vpl(double taxa, List<double> fluxo) {
  var total = 0.0;
  for (var t = 0; t < fluxo.length; t++) {
    total += fluxo[t] / math.pow(1 + taxa, t);
  }
  return total;
}

/// Quantas vezes o fluxo troca de sinal. Mais de uma => TIR pode ser ambígua.
int trocasDeSinal(List<double> fluxo) {
  var trocas = 0;
  double? anterior;
  for (final v in fluxo) {
    if (v == 0) continue;
    if (anterior != null && (anterior < 0) != (v < 0)) trocas++;
    anterior = v;
  }
  return trocas;
}

/// Taxa Interna de Retorno: taxa que zera o VPL (varredura + bissecção).
double? tir(List<double> fluxo) {
  const minTaxa = -0.99;
  const maxTaxa = 10.0;
  const passos = 2000;
  var a = minTaxa;
  var fa = vpl(a, fluxo);
  for (var k = 1; k <= passos; k++) {
    final b = minTaxa + (maxTaxa - minTaxa) * k / passos;
    final fb = vpl(b, fluxo);
    if (fa == 0) return a;
    if (fa * fb < 0) return _bisseccao(fluxo, a, b);
    a = b;
    fa = fb;
  }
  return fa == 0 ? a : null;
}

double _bisseccao(List<double> fluxo, double baixo, double alto) {
  var lo = baixo;
  var hi = alto;
  var flo = vpl(lo, fluxo);
  for (var i = 0; i < 100; i++) {
    final meio = (lo + hi) / 2;
    final fm = vpl(meio, fluxo);
    if (flo * fm <= 0) {
      hi = meio;
    } else {
      lo = meio;
      flo = fm;
    }
  }
  return (lo + hi) / 2;
}

/// TIR Modificada: saídas descontadas e entradas capitalizadas à mesma [taxa]
/// (custo de capital), como no material da FGV.
double? tirm(List<double> fluxo, {required double taxa}) {
  final n = fluxo.length - 1;
  if (n < 1) return null;
  var vpSaidas = 0.0;
  var vfEntradas = 0.0;
  for (var t = 0; t <= n; t++) {
    if (fluxo[t] < 0) {
      vpSaidas += -fluxo[t] / math.pow(1 + taxa, t);
    } else {
      vfEntradas += fluxo[t] * math.pow(1 + taxa, n - t);
    }
  }
  if (vpSaidas == 0 || vfEntradas == 0) return null;
  return math.pow(vfEntradas / vpSaidas, 1 / n).toDouble() - 1;
}

/// Payback em anos (com fração). [taxa] = 0: simples; > 0: descontado.
/// Retorna null se não recuperar dentro do horizonte.
double? payback(List<double> fluxo, {double taxa = 0}) {
  if (fluxo.isEmpty || fluxo[0] >= 0) return 0.0;
  var acumulado = 0.0;
  for (var t = 0; t < fluxo.length; t++) {
    final vp = fluxo[t] / math.pow(1 + taxa, t);
    final anterior = acumulado;
    acumulado += vp;
    if (t > 0 && anterior < 0 && acumulado >= 0) {
      return (t - 1) + (-anterior) / vp;
    }
  }
  return null;
}

/// Índice de Lucratividade: VP das entradas / VP das saídas (> 1 cria valor).
double? indiceLucratividade(double taxa, List<double> fluxo) {
  var vpEntradas = 0.0;
  var vpSaidas = 0.0;
  for (var t = 0; t < fluxo.length; t++) {
    final vp = fluxo[t] / math.pow(1 + taxa, t);
    if (vp >= 0) {
      vpEntradas += vp;
    } else {
      vpSaidas += -vp;
    }
  }
  return vpSaidas == 0 ? null : vpEntradas / vpSaidas;
}

/// Soma acumulada dos fluxos descontados à [taxa], ano a ano.
List<double> fluxoAcumuladoDescontado(List<double> fluxo, double taxa) {
  final saida = <double>[];
  var acumulado = 0.0;
  for (var t = 0; t < fluxo.length; t++) {
    acumulado += fluxo[t] / math.pow(1 + taxa, t);
    saida.add(acumulado);
  }
  return saida;
}

/// Serviço do model: recebe uma [Entrada] e devolve um [Resultado].
class AnaliseViabilidade {
  const AnaliseViabilidade();

  Resultado avaliar(Entrada e) {
    final fluxo = e.fluxoDoNegocio;
    final n = e.anos;
    final rf = math.max(-0.99, e.taxaLivreDeRisco);
    final tma = math.max(-0.99, e.tma);

    final vplTma = vpl(tma, fluxo);
    final montanteInv = e.capitalInicial * math.pow(1 + rf, n);
    var montanteEmp = 0.0;
    for (var t = 1; t <= n; t++) {
      montanteEmp += fluxo[t] * math.pow(1 + rf, n - t);
    }

    final tirCalculada = tir(fluxo);
    var pvEntradas = 0.0;
    for (var t = 0; t < fluxo.length; t++) {
      if (fluxo[t] > 0) pvEntradas += fluxo[t] / math.pow(1 + tma, t);
    }

    final avisos = <String>[];
    if (e.proLaboreAnual == 0) {
      avisos.add('Pró-labore zero: o seu trabalho está sendo tratado como se fosse de graça.');
    }
    if (trocasDeSinal(fluxo) > 1) {
      avisos.add('O fluxo troca de sinal mais de uma vez: a TIR pode ser ambígua, confie no VPL.');
    }
    if (tirCalculada == null) {
      avisos.add('Não foi possível calcular a TIR para este fluxo.');
    }
    if (e.valorResidual > 0 &&
        pvEntradas > 0 &&
        (e.valorResidual / math.pow(1 + tma, n)) / pvEntradas > 0.4) {
      avisos.add('O valor residual responde por mais de 40% das entradas em valor presente: teste também com valor residual zero.');
    }

    return Resultado(
      entrada: e,
      tma: tma,
      vplNaTma: vplTma,
      tir: tirCalculada,
      tirm: tirm(fluxo, taxa: tma),
      payback: payback(fluxo),
      paybackDescontado: payback(fluxo, taxa: tma),
      indiceLucratividade: indiceLucratividade(tma, fluxo),
      montanteInvestindo: montanteInv,
      montanteEmpreendendo: montanteEmp,
      acumuladoComPremio: fluxoAcumuladoDescontado(fluxo, tma),
      acumuladoSemPremio: fluxoAcumuladoDescontado(fluxo, rf),
      veredito: vplTma.abs() < 0.005
          ? Veredito.indiferente
          : (vplTma > 0 ? Veredito.empreender : Veredito.investir),
      avisos: avisos,
    );
  }
}
