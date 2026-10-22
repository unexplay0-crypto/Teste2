import 'package:flutter/material.dart';
import 'design/unex_design_tokens.dart';
import 'package:video_player/video_player.dart';
import 'core.dart';
import 'widgets.dart';

class MobileLayoutScreen extends StatelessWidget {
  final int activeSection;
  final ValueChanged<int> onSectionChanged;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<StreamItem> filteredItems;
  final List<SeriesGroup> groupedSeries;
  final StreamItem? selectedLiveChannel;
  final ValueChanged<StreamItem> onLiveChannelSelected;
  final void Function(StreamItem item, List<StreamItem> playlist) onOpenFullScreen;
  final ValueChanged<StreamItem> onOpenMovieDetails;
  final ValueChanged<SeriesGroup> onOpenSeriesDetails;
  final Set<String> favorites;
  final ValueChanged<String> onToggleFavorite;
  final Map<String, double> watchProgress;
  final bool isAdultUnlocked;
  final Future<bool> Function() onUnlockAdult;
  final VoidCallback onRefreshPlaylist;
  final VoidCallback onSwitchAccount;

  const MobileLayoutScreen({
    super.key,
    required this.activeSection,
    required this.onSectionChanged,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.filteredItems,
    required this.groupedSeries,
    required this.selectedLiveChannel,
    required this.onLiveChannelSelected,
    required this.onOpenFullScreen,
    required this.onOpenMovieDetails,
    required this.onOpenSeriesDetails,
    required this.favorites,
    required this.onToggleFavorite,
    required this.watchProgress,
    required this.isAdultUnlocked,
    required this.onUnlockAdult,
    required this.onRefreshPlaylist,
    required this.onSwitchAccount,
  });

  bool get _isFavoritesLive =>
      activeSection == 3 &&
      (selectedCategory == 'Canais' || selectedCategory == 'TV ao Vivo');

  bool get _isDisplayingSeries =>
      activeSection == 2 || (activeSection == 3 && selectedCategory == 'Séries');

  @override
  Widget build(BuildContext context) {
    final engine = SharedStreamEngine.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0F17),
        elevation: 0,
        title: const Text(
          'UNEX PLAY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: UnexDesignTokens.primary,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'speed':
                  showSpeedTestDialog(context, deviceMode: DeviceMode.mobile);
                  break;
                case 'refresh':
                  onRefreshPlaylist();
                  break;
                case 'switch':
                  onSwitchAccount();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'speed',
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded),
                    SizedBox(width: 12),
                    Text('Teste de velocidade'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded),
                    SizedBox(width: 12),
                    Text('Atualizar lista'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 12),
                    Text('Trocar lista'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquisar canal, filme ou série...',
                prefixIcon: const Icon(Icons.search_rounded, color: UnexDesignTokens.primary),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF111622),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Categorias / Subcategorias de Favoritos
          if (categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSelected = cat == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: UnexDesignTokens.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (_) => onCategorySelected(cat),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Mini Player ao Vivo (quando em TV ao Vivo ou Favoritos -> Canais)
          if ((activeSection == 0 || _isFavoritesLive) && selectedLiveChannel != null)
            GestureDetector(
              onTap: () => onOpenFullScreen(selectedLiveChannel!, filteredItems),
              child: Container(
                height: (MediaQuery.of(context).size.height * 0.19)
                    .clamp(118.0, 160.0)
                    .toDouble(),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListenableBuilder(
                  listenable: engine,
                  builder: (context, _) {
                    if (engine.isFullScreenActive) {
                      return const SizedBox.expand(child: ColoredBox(color: Colors.black));
                    }
                    final ctrl = engine.controller;
                    if (!engine.isReady || ctrl == null || !ctrl.value.isInitialized) {
                      return const Center(
                        child: CircularProgressIndicator(color: UnexDesignTokens.primary),
                      );
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: ctrl.value.aspectRatio > 0
                                ? ctrl.value.aspectRatio
                                : (16 / 9),
                            child: VideoPlayer(ctrl),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen_rounded, size: 16, color: UnexDesignTokens.primary),
                                SizedBox(width: 4),
                                Text('Tela Cheia', style: TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          // Lista de Canais ou Grade de Pôsteres
          Expanded(
            child: (activeSection == 0 || _isFavoritesLive)
                ? ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, idx) {
                      final channel = filteredItems[idx];
                      final isSelected = selectedLiveChannel?.id == channel.id;
                      final isFav = favorites.contains(channel.id);
                      final isLocked = channel.isAdult && !isAdultUnlocked;

                      return Card(
                        color: isSelected ? const Color(0xFF162238) : const Color(0xFF10141E),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: buildChannelLogo(channel.logo, size: 40, isLocked: isLocked),
                          title: Text(
                            channel.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            channel.group,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 11, color: Colors.white54),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isFav ? Colors.amber : Colors.white54,
                            ),
                            onPressed: () {
                              onToggleFavorite(channel.id);
                              showQuickFavoriteToast(
                                context,
                                title: channel.name,
                                isAdded: !isFav,
                              );
                            },
                          ),
                          onTap: () async {
                            if (isLocked) {
                              final ok = await onUnlockAdult();
                              if (!ok) return;
                            }
                            if (isSelected) {
                              onOpenFullScreen(channel, filteredItems);
                            } else {
                              onLiveChannelSelected(channel);
                            }
                          },
                          onLongPress: () {
                            onToggleFavorite(channel.id);
                            showQuickFavoriteToast(
                              context,
                              title: channel.name,
                              isAdded: !isFav,
                            );
                          },
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width < 420
                          ? 2
                          : MediaQuery.of(context).size.width < 720
                              ? 3
                              : 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.67,
                    ),
                    itemCount: _isDisplayingSeries ? groupedSeries.length : filteredItems.length,
                    itemBuilder: (context, idx) {
                      if (_isDisplayingSeries) {
                        final series = groupedSeries[idx];
                        final totalEps = series.seasons.values
                            .fold<int>(0, (sum, list) => sum + list.length);
                        final isFav = favorites.contains('series:${series.title}') ||
                            series.seasons.values
                                .any((eps) => eps.any((ep) => favorites.contains(ep.id)));

                        return GestureDetector(
                          onTap: () => onOpenSeriesDetails(series),
                          onLongPress: () {
                            final allEps = series.seasons.values.expand((e) => e).toList();
                            if (allEps.isNotEmpty) {
                              onToggleFavorite(allEps.first.id);
                              showQuickFavoriteToast(
                                context,
                                title: series.title,
                                isAdded: !isFav,
                              );
                            }
                          },
                          child: buildStreamingPosterCard(
                            title: series.title,
                            subtitle: '${series.seasons.length} Temp • $totalEps Eps',
                            logoUrl: series.logo,
                            badgeText: 'SÉRIE',
                            isFocused: false,
                            isFavorite: isFav,
                          ),
                        );
                      } else {
                        final item = filteredItems[idx];
                        final isFav = favorites.contains(item.id);
                        final isLocked = item.isAdult && !isAdultUnlocked;

                        return GestureDetector(
                          onTap: () async {
                            if (isLocked) {
                              final ok = await onUnlockAdult();
                              if (!ok) return;
                            }
                            onOpenMovieDetails(item);
                          },
                          onLongPress: () {
                            onToggleFavorite(item.id);
                            showQuickFavoriteToast(
                              context,
                              title: item.name,
                              isAdded: !isFav,
                            );
                          },
                          child: buildStreamingPosterCard(
                            title: item.name,
                            subtitle: item.group,
                            logoUrl: item.logo,
                            badgeText: item.qualityTag,
                            isFocused: false,
                            isFavorite: isFav,
                            isAdultLocked: isLocked,
                            progress: watchProgress[item.id],
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activeSection.clamp(0, 4),
        onTap: onSectionChanged,
        backgroundColor: const Color(0xFF0C0F17),
        selectedItemColor: UnexDesignTokens.primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.live_tv_rounded), label: 'Ao Vivo'),
          BottomNavigationBarItem(icon: Icon(Icons.movie_creation_rounded), label: 'Filmes'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Séries'),
          BottomNavigationBarItem(icon: Icon(Icons.star_rounded), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Histórico'),
        ],
      ),
    );
  }
}
