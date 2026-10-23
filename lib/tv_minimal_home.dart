// ============================================================================
// UNEX PLAY — TELA INICIAL MINIMALISTA (TV-only)
// Fundo preto, texto branco, minimo de escrita — toda informacao essencial
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'core.dart';
import 'tmdb_banners.dart';

class MinimalTvHome extends StatelessWidget {
  final List<Suggestion> suggestions;
  final List<StreamItem> liveChannels;
  final List<StreamItem> movies;
  final ValueChanged<Suggestion> onSelectBanner;
  final ValueChanged<StreamItem> onOpenItem;
  final VoidCallback onGoToLive;
  final VoidCallback onGoToMovies;
  final VoidCallback onGoToSeries;
  final VoidCallback onGoToFavorites;
  final VoidCallback onGoToSettings;

  const MinimalTvHome({
    super.key,
    required this.suggestions,
    required this.liveChannels,
    required this.movies,
    required this.onSelectBanner,
    required this.onOpenItem,
    required this.onGoToLive,
    required this.onGoToMovies,
    required this.onGoToSeries,
    required this.onGoToFavorites,
    required this.onGoToSettings,
  });

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalSidebar(
            onGoToLive: onGoToLive,
            onGoToMovies: onGoToMovies,
            onGoToSeries: onGoToSeries,
            onGoToFavorites: onGoToFavorites,
            onGoToSettings: onGoToSettings,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 8),
                // LOGO minimalista (so texto, sem cor)
                const Text('UNEX PLAY',
                    style: TextStyle(
                        color: TvTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6)),
                const SizedBox(height: 20),
                // HERO — banner com backdrop, texto minimo
                if (suggestions.isNotEmpty)
                  _HeroBanner(
                    suggestion: suggestions.first,
                    onSelect: () => onSelectBanner(suggestions.first),
                  ),
                MinimalSectionHeader(title: 'AO VIVO', count: liveChannels.length),
                _ChannelRow(channels: liveChannels.take(10).toList(), onOpen: onOpenItem),
                MinimalSectionHeader(title: 'FILMES', count: movies.length),
                _MovieRow(movies: movies.take(10).toList(), onOpen: onOpenItem),
                const SizedBox(height: 40),
                const Center(
                  child: Text('↑↓←→ navegar   ·   OK selecionar   ·   VOLTAR sair',
                      style: TvTheme.caption),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Barra lateral minimalista — so icones brancos, rotulo minimo
class _MinimalSidebar extends StatelessWidget {
  final VoidCallback onGoToLive, onGoToMovies, onGoToSeries, onGoToFavorites, onGoToSettings;
  const _MinimalSidebar({
    required this.onGoToLive,
    required this.onGoToMovies,
    required this.onGoToSeries,
    required this.onGoToFavorites,
    required this.onGoToSettings,
  });
  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.live_tv_rounded, 'label': 'AO VIVO', 'onTap': onGoToLive},
      {'icon': Icons.movie_rounded, 'label': 'FILMES', 'onTap': onGoToMovies},
      {'icon': Icons.video_library_rounded, 'label': 'SÉRIES', 'onTap': onGoToSeries},
      {'icon': Icons.star_border_rounded, 'label': 'LISTA', 'onTap': onGoToFavorites},
      {'icon': Icons.settings_outlined, 'label': 'AJUSTES', 'onTap': onGoToSettings},
    ];
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          const SizedBox(height: 8),
          for (var i = 0; i < items.length; i++) ...[
            MinimalFocusable(
              autofocus: i == 0,
              onSelect: items[i]['onTap'] as VoidCallback,
              child: Container(
                width: 72,
                height: 64,
                decoration: BoxDecoration(
                  color: TvTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i]['icon'] as IconData,
                        color: TvTheme.textPrimary, size: 22),
                    const SizedBox(height: 4),
                    Text(items[i]['label'] as String,
                        style: const TextStyle(
                            color: TvTheme.textSecondary, fontSize: 9, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// Hero minimalista — imagem de fundo + titulo grande + linha fina "play"
class _HeroBanner extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onSelect;
  const _HeroBanner({required this.suggestion, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    final s = suggestion.tmdb;
    return MinimalFocusable(
      onSelect: onSelect,
      scale: 1.02,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: TvTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (s.backdropUrl.isNotEmpty)
              Image.network(s.backdropUrl,
                  fit: BoxFit.cover,
                  cacheWidth: 1280,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            // gradiente preto suave (minimalista)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.15),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Apenas o essencial: titulo + ano + nota, em branco
                  Text(s.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (s.releaseDate.isNotEmpty)
                        Text(s.releaseDate.substring(0, 4),
                            style: TvTheme.body),
                      const SizedBox(width: 14),
                      const Icon(Icons.star, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(s.voteAverage.toStringAsFixed(1),
                          style: TvTheme.body),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('▶  ASSISTIR',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Linha de canais — logos quadrados minimalistas, nome abaixo em cinza
class _ChannelRow extends StatelessWidget {
  final List<StreamItem> channels;
  final ValueChanged<StreamItem> onOpen;
  const _ChannelRow({required this.channels, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Text('Nenhum canal.', style: TvTheme.body);
    }
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: channels.length,
        itemBuilder: (_, i) {
          final ch = channels[i];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: MinimalFocusable(
              onSelect: () => onOpen(ch),
              child: SizedBox(
                width: 80,
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: TvTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ch.logo.isNotEmpty
                          ? Image.network(ch.logo, fit: BoxFit.cover, cacheWidth: 128,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.live_tv_rounded, color: TvTheme.textMuted))
                          : const Icon(Icons.live_tv_rounded, color: TvTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(ch.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: TvTheme.textSecondary, fontSize: 10)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Linha de filmes — posters com titulo minimo
class _MovieRow extends StatelessWidget {
  final List<StreamItem> movies;
  final ValueChanged<StreamItem> onOpen;
  const _MovieRow({required this.movies, required this.onOpen});
  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const Text('Nenhum filme.', style: TvTheme.body);
    }
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        itemBuilder: (_, i) {
          final m = movies[i];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: MinimalFocusable(
              onSelect: () => onOpen(m),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: TvTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: m.logo.isNotEmpty
                          ? Image.network(m.logo, fit: BoxFit.cover, cacheWidth: 240,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) => const SizedBox())
                          : const SizedBox(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(m.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: TvTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
