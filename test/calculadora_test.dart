import 'package:calculadora_viabilidade/controllers/calculadora_controller.dart';
import 'package:calculadora_viabilidade/models/analise_viabilidade.dart';
import 'package:calculadora_viabilidade/models/entrada.dart';
import 'package:calculadora_viabilidade/models/resultado.dart';
import 'package:calculadora_viabilidade/utils/formatadores.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Model: exemplos do PDF (Zygel, FGV)', () {
    const fluxo = [-4000.0, 2000.0, 4000.0];
    const a = [-24000.0, 10000.0, 10000.0, 10000.0, 10000.0];
    const b = [-24000.0, 0.0, 5000.0, 10000.0, 33000.0];

    test('VPL e TIR', () {
      expect(vpl(0.10, fluxo), closeTo(1123.97, 0.01));
      expect(vpl(0.30, fluxo), closeTo(-94.67, 0.01));
      expect(tir(fluxo)!, closeTo(0.2808, 0.0001));
      expect(vpl(0.10, a), closeTo(7698.65, 0.01));
      expect(tir(b)!, closeTo(0.2165, 0.0001));
    });

    test('TIRM, payback e índice de lucratividade', () {
      expect(tirm(a, taxa: 0.10)!, closeTo(0.1792, 0.0001));
      expect(tirm(b, taxa: 0.10)!, closeTo(0.2017, 0.0001));
      const f = [-400000.0, 80000.0, 90000.0, 120000.0, 130000.0, 100000.0, 70000.0];
      expect(payback(f)!, closeTo(3.846, 0.001));
      expect(payback(f, taxa: 0.10)!, closeTo(5.30, 0.01));
      expect(indiceLucratividade(0.10, const [-2000.0, 1100.0, 1210.0, 1331.0])!,
          closeTo(1.5, 1e-6));
    });
  });

  group('Model: investir x empreender', () {
    const analise = AnaliseViabilidade();

    test('com prêmio de 10 p.p. o veredito é investir', () {
      final r = analise.avaliar(const Entrada());
      expect(r.vplNaTma, closeTo(-5140.82, 0.01));
      expect(r.acumuladoComPremio.last, closeTo(r.vplNaTma, 1e-6));
      expect(r.veredito, Veredito.investir);
    });

    test('sem prêmio, diferença de montantes = VPL x (1+i)^t', () {
      final r = analise.avaliar(const Entrada(premioDeRisco: 0));
      expect(r.vplNaTma, closeTo(25815.74, 0.01));
      expect(r.montanteInvestindo, closeTo(161051.0, 0.01));
      expect(r.diferencaDeMontantes, closeTo(r.vplNaTma * 1.61051, 0.01));
      expect(r.veredito, Veredito.empreender);
    });
  });

  group('Controller', () {
    test('lê valores no formato brasileiro e recalcula', () {
      final c = CalculadoraController();
      c.atualizarCampo(Campo.capital, '200.000,00');
      expect(c.entrada.capitalInicial, 200000);
      expect(c.resultado, isNotNull);
    });

    test('valida prazo e volta ao normal ao corrigir', () {
      final c = CalculadoraController();
      c.atualizarCampo(Campo.anos, '0');
      expect(c.resultado, isNull);
      expect(c.erroDe(Campo.anos), isNotNull);
      c.atualizarCampo(Campo.anos, '5');
      expect(c.resultado, isNotNull);
      expect(c.erroDe(Campo.anos), isNull);
    });

    test('notifica a View quando o prêmio muda', () {
      final c = CalculadoraController();
      var avisos = 0;
      c.addListener(() => avisos++);
      c.atualizarPremio(0);
      expect(avisos, 1);
      expect(c.entrada.premioDeRisco, 0);
    });
  });

  group('Máscara de dinheiro', () {
    test('agrupa milhares e limita a 2 casas', () {
      final r = MoedaBrFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1234567,891',
          selection: TextSelection.collapsed(offset: 11),
        ),
      );
      expect(r.text, '1.234.567,89');
    });
  });
}
