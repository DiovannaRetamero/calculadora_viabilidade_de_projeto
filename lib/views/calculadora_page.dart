import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/calculadora_controller.dart';
import '../models/resultado.dart';
import '../utils/formatadores.dart';
import 'grafico_fluxo.dart';

/// VIEW: só desenha o estado do controller e repassa os eventos a ele.
/// Nenhuma conta financeira acontece aqui.
class CalculadoraPage extends StatelessWidget {
  const CalculadoraPage({super.key, required this.controller});

  final CalculadoraController controller;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Investir ou empreender',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: tema.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compare o negócio com a alternativa segura, no mesmo prazo e com o mesmo capital.',
                    style: tema.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  _Formulario(controller: controller),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _Resultados(controller: controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Formulario extends StatefulWidget {
  const _Formulario({required this.controller});

  final CalculadoraController controller;

  @override
  State<_Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<_Formulario> {
  late final Map<Campo, TextEditingController> _txt;

  @override
  void initState() {
    super.initState();
    final e = widget.controller.entrada;
    _txt = {
      Campo.capital: TextEditingController(text: numeroBR(e.capitalInicial)),
      Campo.anos: TextEditingController(text: '${e.anos}'),
      Campo.taxa: TextEditingController(text: numeroBR(e.taxaLivreDeRisco * 100)),
      Campo.faturamento: TextEditingController(text: numeroBR(e.faturamentoAnual)),
      Campo.despesas: TextEditingController(text: numeroBR(e.despesasAnuais)),
      Campo.proLabore: TextEditingController(text: numeroBR(e.proLaboreAnual)),
      Campo.valorResidual: TextEditingController(text: numeroBR(e.valorResidual)),
    };
  }

  @override
  void dispose() {
    for (final c in _txt.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _campo(
    Campo campo,
    String rotulo, {
    bool moeda = true,
    List<TextInputFormatter>? formatadores,
  }) {
    final ctrl = widget.controller;
    return TextField(
      controller: _txt[campo],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: formatadores ?? [MoedaBrFormatter()],
      decoration: InputDecoration(
        labelText: rotulo,
        prefixText: moeda ? 'R\$ ' : null,
        errorText: ctrl.erroDe(campo),
        border: const OutlineInputBorder(),
      ),
      onChanged: (t) => ctrl.atualizarCampo(campo, t),
      // Ao concluir, completa os centavos (100.000 -> 100.000,00).
      onEditingComplete: moeda
          ? () {
              _txt[campo]!.text = numeroBR(lerNumeroBR(_txt[campo]!.text));
              FocusScope.of(context).nextFocus();
            }
          : null,
    );
  }

  Widget _secao(String texto, ColorScheme cs) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: cs.primary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final e = widget.controller.entrada;
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _secao('CAPITAL E PRAZO', cs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _campo(Campo.capital, 'Capital inicial')),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _campo(Campo.anos, 'Prazo (anos)',
                          moeda: false,
                          formatadores: [FilteringTextInputFormatter.digitsOnly]),
                    ),
                  ],
                ),
                _secao('ALTERNATIVA SEGURA', cs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _campo(Campo.taxa, 'Taxa livre de risco (% a.a.)',
                          moeda: false,
                          formatadores: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))
                          ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'TMA ${fmtPercentual(e.tma)} a.a.',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Prêmio de risco'),
                    Text('${numeroBR(e.premioDeRisco * 100)} p.p.',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                Slider(
                  value: (e.premioDeRisco * 100).clamp(0, 20).toDouble(),
                  min: 0,
                  max: 20,
                  divisions: 40,
                  onChanged: widget.controller.atualizarPremio,
                ),
                _secao('NEGÓCIO', cs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campo(Campo.faturamento, 'Faturamento anual')),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(Campo.despesas, 'Despesas anuais')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _campo(Campo.proLabore, 'Pró-labore anual')),
                    const SizedBox(width: 12),
                    Expanded(child: _campo(Campo.valorResidual, 'Valor residual')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Resultados extends StatelessWidget {
  const _Resultados({required this.controller});

  final CalculadoraController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.resultado;
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    if (r == null) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Corrija os campos destacados para ver o resultado.',
              style: TextStyle(color: cs.error)),
        ),
      );
    }

    final e = r.entrada;
    final n = e.anos;
    final temPremio = e.premioDeRisco > 0;
    final (fundo, tinta, titulo) = switch (r.veredito) {
      Veredito.empreender => (
          cs.primaryContainer,
          cs.onPrimaryContainer,
          'Vale mais a pena empreender'
        ),
      Veredito.investir => (
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
          'Vale mais a pena investir'
        ),
      Veredito.indiferente => (
          cs.secondaryContainer,
          cs.onSecondaryContainer,
          'Indiferente: os dois caminhos se equivalem'
        ),
    };
    final corA = tema.brightness == Brightness.dark
        ? const Color(0xFFF0A24A)
        : const Color(0xFFB4540A);
    final sentido = r.vplNaTma < 0 ? 'a menos' : 'a mais';
    final legendaA = temPremio
        ? 'Com prêmio de ${numeroBR(e.premioDeRisco * 100)} p.p. (TMA ${fmtPercentual(r.tma)})'
        : 'TMA ${fmtPercentual(r.tma)}';
    final ilTexto =
        r.indiceLucratividade == null ? '\u2014' : numeroBR(r.indiceLucratividade!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: fundo,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VEREDITO',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: tinta)),
                Text(titulo,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, color: tinta)),
                const SizedBox(height: 10),
                Text('VPL do negócio na TMA de ${fmtPercentual(r.tma)}',
                    style: TextStyle(color: tinta)),
                Text(fmtMoeda(r.vplNaTma),
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800, color: tinta)),
                const SizedBox(height: 6),
                Text(
                    'Em valores de hoje, o negócio gera ${fmtMoeda(r.vplNaTma.abs())} $sentido '
                    'do que a alternativa segura, já descontado o risco informado.',
                    style: TextStyle(color: tinta)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fluxo acumulado descontado (R\$)',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 18,
                  runSpacing: 4,
                  children: [
                    _Legenda(corA, '$legendaA: ${fmtMoeda(r.acumuladoComPremio[n])}'),
                    if (temPremio)
                      _Legenda(cs.primary,
                          'Sem prêmio (TMA ${fmtPercentual(e.taxaLivreDeRisco)}): ${fmtMoeda(r.acumuladoSemPremio[n])}'),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: GraficoFluxo(
                    comPremio: r.acumuladoComPremio,
                    semPremio: temPremio ? r.acumuladoSemPremio : null,
                    corComPremio: corA,
                    corSemPremio: cs.primary,
                    corGrade: cs.outlineVariant,
                    corTexto: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    'Quando a linha cruza o zero, o investimento foi recuperado em valores de hoje.',
                    style: tema.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Indicador('TIR', fmtPercentual(r.tir), 'máximo custo de capital'),
            _Indicador('TIRM', fmtPercentual(r.tirm), 'rentabilidade esperada'),
            _Indicador('Índice de lucratividade', ilTexto, 'acima de 1 cria valor'),
            _Indicador('Payback simples', fmtAnos(r.payback)),
            _Indicador('Payback descontado', fmtAnos(r.paybackDescontado)),
            _Indicador('Lucro anual', fmtMoeda(e.lucroAnual),
                'faturamento \u2212 despesas \u2212 pró-labore'),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Em $n ${n == 1 ? 'ano' : 'anos'}, reinvestindo à taxa livre de risco (sem prêmio)',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Indicador('Investindo', fmtMoeda(r.montanteInvestindo)),
                    _Indicador('Empreendendo', fmtMoeda(r.montanteEmpreendendo)),
                    _Indicador('Diferença', fmtMoeda(r.diferencaDeMontantes)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (r.avisos.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final aviso in r.avisos)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('\u2022 $aviso', style: tema.textTheme.bodySmall),
            ),
        ],
        const SizedBox(height: 14),
        Text(
          'Estimativas com base nos dados informados; não são recomendação financeira. '
          'Use taxa nominal com fluxo nominal, ou taxa real com fluxo real.',
          style: tema.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda(this.cor, this.texto);

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador(this.rotulo, this.valor, [this.detalhe]);

  final String rotulo;
  final String valor;
  final String? detalhe;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 170,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: t.bodySmall),
              Text(valor,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (detalhe != null) Text(detalhe!, style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
