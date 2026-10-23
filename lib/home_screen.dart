// ============================================================================
// TELA INICIAL (HOME / INICIO) — Dashboard estilo streaming
// Estilo: banner hero TMDB + linha Canais ao Vivo + linha Filmes em Destaque
// Adaptativa: TV (menu lateral) / Celular
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core.dart';
import 'widgets.dart';
import 'tmdb_banners.dart';

class HomeDashboard extends StatelessWidget {
  final List<Suggestion> suggestions;
  final List<StreamItem> liveChannels;
  final List<StreamItem> featuredMovies;
  final DeviceMode deviceMode;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Suggestion> onSelectBanner;
  final ValueChanged<StreamItem> onOpenChannel;
  final ValueChanged<StreamItem> onOpenMovie;
  final VoidCallback onSeeAllChannels;
  final VoidCallback onSeeAllMovies;
  final VoidCallback onGoToLive;
  final VoidCallback onGoToMovies;
  final VoidCallback onGoToSeries;
  final VoidCallback onGoToFavorites;
  final VoidCallback onGoToSettings;

  const HomeDashboard({
    super.key,
    required this.suggestions,
    required this.liveChannels,
    required this.featuredMovies,
    required this.deviceMode,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelectBanner,
    required this.onOpenChannel,
    required this.onOpenMovie,
    required this.onSeeAllChannels,
    required this.onSeeAllMovies,
    required this.onGoToLive,
    required this.onGoToMovies,
    required this.onGoToSeries,
    required this.onGoToFavorites,
    required this.onGoToSettings,
  });

  bool get _isTv => deviceMode == DeviceMode.tv;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Row(
        children: [
          if (_isTv) _buildSidebar(context),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(bottom: _isTv ? 16 : 80),
                    children: [
                      if (suggestions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: BannerCarousel(
                            suggestions: suggestions,
                            isTv: _isTv,
                            onSelect: onSelectBanner,
                          ),
                        ),
                      _buildSectionHeader(context, 'Canais ao Vivo', onSeeAllChannels),
                      _buildLiveChannelsRow(),
                      const SizedBox(height: 16),
                      _buildSectionHeader(context, 'Filmes em Destaque', onSeeAllMovies),
                      _buildMoviesRow(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Início', 'onTap': () {}},
      {'icon': Icons.live_tv_rounded, 'label': 'TV ao Vivo', 'onTap': onGoToLive},
      {'icon': Icons.movie_creation_rounded, 'label': 'Filmes', 'onTap': onGoToMovies},
      {'icon': Icons.video_library_rounded, 'label': 'Séries', 'onTap': onGoToSeries},
      {'icon': Icons.star_rounded, 'label': 'Minha Lista', 'onTap': onGoToFavorites},
      {'icon': Icons.settings_rounded, 'label': 'Configurações', 'onTap': onGoToSettings},
    ];
    return Container(
      width: 106,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0F17),
        border: Border(right: BorderSide(color: Color(0x14FFFFFF), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0088FF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('UNEX',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  final bool selected = idx == 0;
                  return TVFocusableItem(
                    autoScroll: false,
                    onSelect: item['onTap'] as VoidCallback,
                    builder: (context, focused) => AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 86,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: focused ? const Color(0xFF00E5FF) : selected ? const Color(0xFF00E5FF).withOpacity(0.14) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item['icon'] as IconData, size: 20,
                              color: focused ? Colors.black : selected ? const Color(0xFF00E5FF) : Colors.white60),
                          const SizedBox(height: 3),
                          Text(item['label'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                  color: focused ? Colors.black : selected ? const Color(0xFF00E5FF) : Colors.white60)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (!_isTv)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0088FF)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('UNEX', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          if (!_isTv) const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: _isTv ? 42 : 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111520),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Buscar filmes, séries, canais...',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70), onPressed: () {}),
          if (_isTv) ...[
            const SizedBox(width: 8),
            const Icon(Icons.wifi_rounded, color: Colors.white54, size: 18),
            const SizedBox(width: 12),
            const Text('UNEX PLAY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.white, fontSize: _isTv ? 18 : 16, fontWeight: FontWeight.w800)),
          TVFocusableItem(
            autoScroll: false,
            onSelect: onSeeAll,
            builder: (context, focused) => Text('Ver todos',
                style: TextStyle(color: focused ? const Color(0xFF00E5FF) : Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChannelsRow() {
    final channels = liveChannels.take(12).toList();
    if (channels.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Nenhum canal disponível.', style: TextStyle(color: Colors.white38)));
    }
    return SizedBox(
      height: _isTv ? 100 : 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: channels.length,
        itemBuilder: (context, idx) {
          final ch = channels[idx];
          return TVFocusableItem(
            autoScroll: false,
            onSelect: () => onOpenChannel(ch),
            builder: (context, focused) => Container(
              width: _isTv ? 84 : 72,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: _isTv ? 64 : 56,
                    height: _isTv ? 64 : 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141926),
                      border: Border.all(color: focused ? const Color(0xFF00E5FF) : Colors.white12, width: focused ? 2.2 : 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ch.logo.isNotEmpty
                        ? Image.network(ch.logo, fit: BoxFit.cover, cacheWidth: 128,
                            errorBuilder: (_, __, ___) => const Icon(Icons.live_tv_rounded, color: Colors.white38))
                        : const Icon(Icons.live_tv_rounded, color: Colors.white38),
                  ),
                  const SizedBox(height: 6),
                  Text(ch.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: focused ? Colors.white : Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoviesRow() {
    final movies = featuredMovies.take(12).toList();
    if (movies.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Nenhum filme em destaque.', style: TextStyle(color: Colors.white38)));
    }
    return SizedBox(
      height: _isTv ? 150 : 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: movies.length,
        itemBuilder: (context, idx) {
          final m = movies[idx];
          return TVFocusableItem(
            autoScroll: false,
            onSelect: () => onOpenMovie(m),
            builder: (context, focused) => AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: _isTv ? 240 : 200,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: focused ? const Color(0xFF00E5FF) : Colors.transparent, width: focused ? 2.2 : 0),
                boxShadow: focused ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 16)] : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  m.logo.isNotEmpty
                      ? Image.network(m.logo, fit: BoxFit.cover, cacheWidth: 480, gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFF141926)))
                      : Container(color: const Color(0xFF141926)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Text(m.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
