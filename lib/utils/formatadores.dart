import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
final _dois = NumberFormat('#,##0.00', 'pt_BR');
final _compacto = NumberFormat.compact(locale: 'pt_BR');

String _menos(String s) => s.replaceAll('-', '\u2212');

/// R$ 1.234,56 (negativos com sinal de menos tipográfico).
String fmtMoeda(double v) => _menos(_brl.format(v));

/// 25 mil, −100 mil (eixos do gráfico).
String fmtCompacto(double v) => _menos(_compacto.format(v));

String fmtPercentual(double? v) =>
    (v == null || !v.isFinite) ? '\u2014' : _menos('${_dois.format(v * 100)}%');

String fmtAnos(double? v) => v == null ? 'não recupera' : '${_dois.format(v)} anos';

/// 1234.5 -> "1.234,50"
String numeroBR(double v) => _dois.format(v);

/// "1.234,50" -> 1234.5 (texto inválido ou vazio vira 0).
double lerNumeroBR(String s) =>
    double.tryParse(s.replaceAll('.', '').replaceAll(',', '.')) ?? 0;

/// Máscara de dinheiro: aceita dígitos e uma vírgula, agrupa milhares com
/// ponto e limita a 2 casas decimais (digitar 1000000 vira 1.000.000).
class MoedaBrFormatter extends TextInputFormatter {
  static final _significativo = RegExp(r'[\d,]');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antigo, TextEditingValue novo) {
    final texto = novo.text;
    final caret = novo.selection.baseOffset.clamp(0, texto.length);
    final aEsquerda = _limpar(texto.substring(0, caret)).length;

    final partes = _limpar(texto).split(',');
    final temVirgula = partes.length > 1;
    var inteiro = partes.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (inteiro.isEmpty && temVirgula) inteiro = '0';
    var centavos = temVirgula ? partes[1] : '';
    if (centavos.length > 2) centavos = centavos.substring(0, 2);

    final agrupado = inteiro.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final saida = agrupado + (temVirgula ? ',$centavos' : '');

    // Mantém o cursor na mesma posição lógica depois de reformatar.
    var contados = 0;
    var pos = 0;
    while (pos < saida.length && contados < aEsquerda) {
      if (_significativo.hasMatch(saida[pos])) contados++;
      pos++;
    }
    return TextEditingValue(
      text: saida,
      selection: TextSelection.collapsed(offset: pos),
    );
  }

  String _limpar(String s) => s.replaceAll(RegExp(r'[^\d,]'), '');
}
