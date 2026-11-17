import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/formatadores.dart';

/// VIEW: gráfico de linhas do fluxo acumulado descontado.
/// [comPremio] é a linha cheia (com sombra até o zero); [semPremio], opcional,
/// é a linha tracejada. O eixo X vai do ano 0 ao ano n.
class GraficoFluxo extends StatelessWidget {
  const GraficoFluxo({
    super.key,
    required this.comPremio,
    this.semPremio,
    required this.corComPremio,
    required this.corSemPremio,
    required this.corGrade,
    required this.corTexto,
  });

  final List<double> comPremio;
  final List<double>? semPremio;
  final Color corComPremio;
  final Color corSemPremio;
  final Color corGrade;
  final Color corTexto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gráfico de linhas do fluxo acumulado descontado por ano',
      child: CustomPaint(
        size: Size.infinite,
        painter: _GraficoPainter(
          a: comPremio,
          b: semPremio,
          corA: corComPremio,
          corB: corSemPremio,
          corGrade: corGrade,
          corTexto: corTexto,
        ),
      ),
    );
  }
}

class _GraficoPainter extends CustomPainter {
  _GraficoPainter({
    required this.a,
    required this.b,
    required this.corA,
    required this.corB,
    required this.corGrade,
    required this.corTexto,
  });

  final List<double> a;
  final List<double>? b;
  final Color corA;
  final Color corB;
  final Color corGrade;
  final Color corTexto;

  @override
  void paint(Canvas canvas, Size size) {
    const esq = 58.0, dir = 16.0, topo = 10.0, base = 28.0;
    final w = size.width - esq - dir;
    final h = size.height - topo - base;
    final n = a.length - 1;
    if (n < 1 || w <= 0 || h <= 0) return;

    final todos = <double>[...a, ...?b, 0.0];
    var mn = todos.reduce(math.min);
    var mx = todos.reduce(math.max);
    final folga = (mx - mn) * 0.06;
    mn -= folga;
    mx += folga;
    double x(int i) => esq + w * i / n;
    double y(double v) => topo + h * (mx - v) / (mx - mn);

    // Grade e eixo Y (a linha do zero fica mais grossa).
    final passo = _passo((mx - mn) / 4);
    final grade = Paint()..color = corGrade;
    for (var k = (mn / passo).ceil(); k * passo <= mx; k++) {
      final v = k * passo;
      grade.strokeWidth = k == 0 ? 1.8 : 1;
      canvas.drawLine(Offset(esq, y(v)), Offset(esq + w, y(v)), grade);
      _texto(canvas, fmtCompacto(v), Offset(esq - 6, y(v)), alinhar: TextAlign.right);
    }

    // Eixo X.
    final passoX = (n / 8).ceil();
    for (var i = 0; i <= n; i += passoX) {
      _texto(canvas, n <= 8 ? 'Ano $i' : '$i', Offset(x(i), size.height - 10),
          alinhar: TextAlign.center);
    }

    Path caminho(List<double> v) {
      final p = Path()..moveTo(x(0), y(v[0]));
      for (var i = 1; i < v.length; i++) {
        p.lineTo(x(i), y(v[i]));
      }
      return p;
    }

    // Sombra entre a linha com prêmio e o zero.
    final area = caminho(a)
      ..lineTo(x(n), y(0))
      ..lineTo(x(0), y(0))
      ..close();
    canvas.drawPath(area, Paint()..color = corA.withAlpha(36));

    final linha = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    if (b != null) {
      _tracejado(canvas, caminho(b!), linha..color = corB);
    }
    canvas.drawPath(caminho(a), linha..color = corA);

    canvas.drawCircle(Offset(x(n), y(a[n])), 4, Paint()..color = corA);
    if (b != null) {
      canvas.drawCircle(Offset(x(n), y(b![n])), 4, Paint()..color = corB);
    }
  }

  double _passo(double bruto) {
    final mag = math.pow(10, (math.log(bruto) / math.ln10).floor()).toDouble();
    final m = bruto / mag;
    final f = m <= 1 ? 1.0 : m <= 2 ? 2.0 : m <= 2.5 ? 2.5 : m <= 5 ? 5.0 : 10.0;
    return f * mag;
  }

  void _tracejado(Canvas canvas, Path caminho, Paint paint) {
    for (final m in caminho.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
        d += 10;
      }
    }
  }

  void _texto(Canvas canvas, String s, Offset p, {required TextAlign alinhar}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 11, color: corTexto)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = switch (alinhar) {
      TextAlign.right => p.dx - tp.width,
      TextAlign.center => p.dx - tp.width / 2,
      _ => p.dx,
    };
    tp.paint(canvas, Offset(dx, p.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GraficoPainter old) => true;
}
