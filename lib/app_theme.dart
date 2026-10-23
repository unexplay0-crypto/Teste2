// ============================================================================
// UNEX PLAY — TEMA MINIMALISTA TV (Preto & Branco)
// Design tokens + SafeArea wrapper + foco padronizado (TV-only)
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvTheme {
  // Cores — minimalista preto e branco
  static const Color bg = Color(0xFF000000);          // fundo preto puro
  static const Color surface = Color(0xFF0A0A0A);     // superficie (cards)
  static const Color surface2 = Color(0xFF141414);    // superficie elevada
  static const Color line = Color(0xFF1F1F1F);        // linhas divisorias suaves
  static const Color textPrimary = Color(0xFFFFFFFF); // branco puro
  static const Color textSecondary = Color(0xFF9A9A9A);// cinza medio
  static const Color textMuted = Color(0xFF555555);   // cinza escuro (minimo)
  static const Color accent = Color(0xFFFFFFFF);      // acento = branco (minimalista)
  static const Color focusRing = Color(0xFFFFFFFF);   // anel de foco branco

  // Tipografia 10-foot (3 metros) — branca, sans-serif, pesos minimos
  static const TextStyle title = TextStyle(
      color: textPrimary, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const TextStyle heading = TextStyle(
      color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600);
  static const TextStyle body = TextStyle(
      color: textSecondary, fontSize: 15, fontWeight: FontWeight.w400, height: 1.35);
  static const TextStyle caption = TextStyle(
      color: textMuted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static const TextStyle label = TextStyle(
      color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600);

  // Area segura contra overscan (48dp laterais / 27dp topo e rodape)
  static const EdgeInsets safeArea =
      EdgeInsets.fromLTRB(48, 27, 48, 27);
}

// Wrapper raiz: fundo preto + area segura — usar em TODAS as telas
class TvScaffold extends StatelessWidget {
  final Widget child;
  const TvScaffold({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TvTheme.bg,
      body: SafeArea(
        child: Padding(padding: TvTheme.safeArea, child: child),
      ),
    );
  }
}

// Item focavel minimalista: sem cor, so anel branco + escala + brilho
class MinimalFocusable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final FocusNode? focusNode;
  final bool autofocus;
  final double scale;
  const MinimalFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.focusNode,
    this.autofocus = false,
    this.scale = 1.06,
  });
  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.enter)) {
          onSelect?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: _FocusedBuilder(builder: (focused) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          transform: Matrix4.diagonal3Values(
            focused ? scale : 1.0,
            focused ? scale : 1.0,
            1.0,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: focused ? TvTheme.focusRing : Colors.transparent,
              width: focused ? 2.5 : 0,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.18),
                      blurRadius: 24,
                      spreadRadius: -4,
                    )
                  ]
                : null,
          ),
          child: child,
        );
      }),
    );
  }
}

class _FocusedBuilder extends StatefulWidget {
  final Widget Function(bool focused) builder;
  const _FocusedBuilder({required this.builder});
  @override
  State<_FocusedBuilder> createState() => _FocusedBuilderState();
}

class _FocusedBuilderState extends State<_FocusedBuilder> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: widget.builder(_focused),
    );
  }
}

// Linha de secao minimalista: titulo + contagem discreta, sem "Ver todos" gritado
class MinimalSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const MinimalSectionHeader({super.key, required this.title, this.count = 0});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 28),
      child: Row(
        children: [
          Text(title, style: TvTheme.heading),
          const SizedBox(width: 10),
          if (count > 0)
            Text('$count', style: TvTheme.caption),
          const Expanded(child: SizedBox()),
          const Text('OK para abrir', style: TextStyle(color: TvTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}
