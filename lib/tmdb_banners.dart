// ============================================================================
// SISTEMA DE SUGESTOES EM DESTAQUE (BANNERS ROTATIVOS) — TMDB + Lista M3U
// Modulo isolado, sem dependencias externas (usa apenas: http, flutter, dart:io)
// ============================================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'core.dart';

const String _kTmdbApiKey = '32b6d20779ed33fce3b731303f3eccb6';
const String _kTmdbBase = 'https://api.themoviedb.org/3';
const String _kTmdbImageBase = 'https://image.tmdb.org/t/p';
const Duration _kCacheValidity = Duration(hours: 24);
const int _kSuggestionCount = 5;
const int _kMatchThreshold = 70; // 0-100

File get _suggestionsCacheFile =>
    File('${Directory.systemTemp.path}/unex_tmdb_suggestions_v1.json');

// ---------------------------------------------------------------------------
// MODELOS
// ---------------------------------------------------------------------------
class FilmeTMDB {
  final int id;
  final String title;
  final String? originalTitle;
  final String? overview;
  final String releaseDate;
  final double voteAverage;
  final double popularity;
  final String? backdropPath;
  final String? posterPath;
  const FilmeTMDB({
    required this.id,
    required this.title,
    this.originalTitle,
    this.overview,
    this.releaseDate = '',
    this.voteAverage = 0,
    this.popularity = 0,
    this.backdropPath,
    this.posterPath,
  });
  factory FilmeTMDB.fromJson(Map<String, dynamic> j) => FilmeTMDB(
        id: (j['id'] as num?)?.toInt() ?? 0,
        title: (j['title'] ?? '').toString(),
        originalTitle: (j['original_title'] ?? '').toString(),
        overview: (j['overview'] ?? '').toString(),
        releaseDate: (j['release_date'] ?? '').toString(),
        voteAverage: (j['vote_average'] as num?)?.toDouble() ?? 0,
        popularity: (j['popularity'] as num?)?.toDouble() ?? 0,
        backdropPath: (j['backdrop_path'] ?? '').toString().isEmpty
            ? null
            : (j['backdrop_path'] as String),
        posterPath: (j['poster_path'] ?? '').toString().isEmpty
            ? null
            : (j['poster_path'] as String),
      );
  int? get year =>
      releaseDate.length >= 4 ? int.tryParse(releaseDate.substring(0, 4)) : null;
  String get backdropUrl => backdropPath != null
      ? '$_kTmdbImageBase/w1280$backdropPath'
      : '';
  String get posterUrl =>
      posterPath != null ? '$_kTmdbImageBase/w500$posterPath' : '';
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'originalTitle': originalTitle,
        'overview': overview,
        'releaseDate': releaseDate,
        'voteAverage': voteAverage,
        'popularity': popularity,
        'backdropPath': backdropPath,
        'posterPath': posterPath,
      };
}

class Suggestion {
  final FilmeTMDB tmdb;
  final String streamUrl;
  final String streamName;
  const Suggestion({
    required this.tmdb,
    required this.streamUrl,
    required this.streamName,
  });
  Map<String, dynamic> toJson() => {
        'tmdb': tmdb.toJson(),
        'streamUrl': streamUrl,
        'streamName': streamName,
      };
  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
        tmdb: FilmeTMDB.fromJson((j['tmdb'] as Map).cast<String, dynamic>()),
        streamUrl: (j['streamUrl'] ?? '').toString(),
        streamName: (j['streamName'] ?? '').toString(),
      );
}

// ---------------------------------------------------------------------------
// NORMALIZACAO + MATCHING FUZZY (Levenshtein ratio)
// ---------------------------------------------------------------------------
final RegExp _yearReg = RegExp(r'\b(19|20)\d{2}\b');
final RegExp _qualityReg = RegExp(
    r'\b(1080p|2160p|4k|uhd|fhd|hd|720p|sd|h265|hevc|dublado|legendado|dub|leg|dual audio)\b',
    caseSensitive: false);
const String _diacritics = 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ';
const String _ascii = 'aaaaaaaceeeeiiiidnoooooøuuuuyby';

String normalizeTitle(String text) {
  String s = text.toLowerCase();
  final buffer = StringBuffer();
  for (final ch in s.split('')) {
    final idx = _diacritics.indexOf(ch);
    buffer.write(idx >= 0 ? _ascii[idx] : ch);
  }
  s = buffer.toString();
  s = s.replaceAll(_qualityReg, ' ');
  s = s.replaceAll(_yearReg, ' ');
  s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

int? extractYear(String title) {
  final m = _yearReg.firstMatch(title);
  return m != null ? int.tryParse(m.group(0)!) : null;
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
  List<int> v1 = List<int>.filled(b.length + 1, 0);
  for (int i = 0; i < a.length; i++) {
    v1[0] = i + 1;
    for (int j = 0; j < b.length; j++) {
      final cost = a.codeUnitAt(i) == b.codeUnitAt(j) ? 0 : 1;
      v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((x, y) => x < y ? x : y);
    }
    final tmp = v0;
    v0 = v1;
    v1 = tmp;
  }
  return v0[b.length];
}

int similarityRatio(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 100;
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 100;
  final dist = _levenshtein(a, b);
  return (((maxLen - dist) / maxLen) * 100).round();
}

StreamItem? findBestMatch(FilmeTMDB movie, List<StreamItem> playlist) {
  final normTitle = normalizeTitle(movie.title);
  final normOriginal = movie.originalTitle != null
      ? normalizeTitle(movie.originalTitle!)
      : '';
  final movieYear = movie.year;
  StreamItem? best;
  int bestScore = 0;
  for (final item in playlist) {
    if (item.type != ContentType.movie) continue;
    final normItem = normalizeTitle(item.name);
    if (normItem.isEmpty) continue;
    var score = similarityRatio(normTitle, normItem);
    if (normOriginal.isNotEmpty) {
      final s2 = similarityRatio(normOriginal, normItem);
      if (s2 > score) score = s2;
    }
    if (movieYear != null) {
      final itemYear = extractYear(item.name);
      if (itemYear != null) {
        if ((itemYear - movieYear).abs() > 1) continue;
        score += 15; // bonus de ano coincidente
      }
    }
    if (score > bestScore && score >= _kMatchThreshold) {
      bestScore = score;
      best = item;
    }
  }
  return best;
}

// ---------------------------------------------------------------------------
// SERVICO TMDB
// ---------------------------------------------------------------------------
class TmdbService {
  static Future<List<FilmeTMDB>> fetchCandidates() async {
    final List<FilmeTMDB> all = [];
    final seen = <int>{};
    const endpoints = ['/movie/top_rated', '/movie/popular', '/movie/upcoming'];
    for (final ep in endpoints) {
      try {
        final uri = Uri.parse(
            '$_kTmdbBase$ep?api_key=$_kTmdbApiKey&language=pt-BR&page=1&region=BR');
        final resp = await http
            .get(uri, headers: const {'User-Agent': 'UNEXPLAY/1.0'})
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) continue;
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        final results = (json['results'] as List?) ?? const [];
        for (final r in results) {
          final m = FilmeTMDB.fromJson((r as Map).cast<String, dynamic>());
          if (m.id == 0 || seen.contains(m.id)) continue;
          if ((m.backdropPath ?? '').isEmpty) continue;
          seen.add(m.id);
          all.add(m);
        }
      } catch (_) {}
    }
    all.sort((a, b) => b.popularity.compareTo(a.popularity));
    return all;
  }
}

// ---------------------------------------------------------------------------
// ORQUESTRADOR + CACHE 24h
// ---------------------------------------------------------------------------
class RecommendationsService {
  RecommendationsService._();
  static final RecommendationsService instance = RecommendationsService._();

  Future<List<Suggestion>> loadCached() async {
    try {
      if (await _suggestionsCacheFile.exists()) {
        final raw = jsonDecode(await _suggestionsCacheFile.readAsString());
        final updatedAt =
            DateTime.fromMillisecondsSinceEpoch(raw['updatedAt'] as int? ?? 0);
        if (DateTime.now().difference(updatedAt) < _kCacheValidity) {
          final list = (raw['items'] as List?) ?? const [];
          return list
              .map((e) => Suggestion.fromJson((e as Map).cast<String, dynamic>()))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<Suggestion>> refresh(List<StreamItem> playlist) async {
    final List<Suggestion> result = [];
    try {
      final candidates = await TmdbService.fetchCandidates();
      for (final movie in candidates) {
        if (result.length >= _kSuggestionCount) break;
        final match = findBestMatch(movie, playlist);
        if (match != null) {
          result.add(Suggestion(
              tmdb: movie, streamUrl: match.url, streamName: match.name));
        }
      }
      if (result.isNotEmpty) {
        await _suggestionsCacheFile.writeAsString(jsonEncode({
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'items': result.map((e) => e.toJson()).toList(),
        }));
      }
    } catch (_) {}
    return result;
  }

  /// Retorna cache imediato se valido; senao busca novo. Sempre nao bloqueia.
  Future<List<Suggestion>> loadOrRefresh(List<StreamItem> playlist) async {
    final cached = await loadCached();
    if (cached.isNotEmpty) return cached;
    return refresh(playlist);
  }
}

// ---------------------------------------------------------------------------
// WIDGET: BANNER ROTATIVO (PageView + Timer 5s + indicadores)
// ---------------------------------------------------------------------------
class BannerCarousel extends StatefulWidget {
  final List<Suggestion> suggestions;
  final ValueChanged<Suggestion> onSelect;
  final bool isTv;
  const BannerCarousel({
    super.key,
    required this.suggestions,
    required this.onSelect,
    this.isTv = false,
  });
  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;
  final FocusNode _bannerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || widget.suggestions.isEmpty) return;
      _index = (_index + 1) % widget.suggestions.length;
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _bannerFocus.dispose();
    super.dispose();
  }

  String _formatDate(String releaseDate) {
    if (releaseDate.length < 4) return '';
    return releaseDate.substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) return const SizedBox.shrink();
    final height = widget.isTv ? 220.0 : 180.0;
    return Focus(
      focusNode: _bannerFocus,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _index = (_index - 1 + widget.suggestions.length) %
              widget.suggestions.length;
          _controller.jumpToPage(_index);
          _startTimer();
          setState(() {});
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _index = (_index + 1) % widget.suggestions.length;
          _controller.jumpToPage(_index);
          _startTimer();
          setState(() {});
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onSelect(widget.suggestions[_index]);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.suggestions.length,
              onPageChanged: (i) {
                _index = i;
                _startTimer();
                setState(() {});
              },
              itemBuilder: (context, i) {
                final s = widget.suggestions[i];
                return GestureDetector(
                  onTap: () => widget.onSelect(s),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (s.tmdb.backdropUrl.isNotEmpty)
                        Image.network(
                          s.tmdb.backdropUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 1280,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF141926)),
                        )
                      else
                        Container(color: const Color(0xFF141926)),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 28,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.tmdb.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.isTv ? 22 : 18,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 6)
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.tmdb.overview ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: widget.isTv ? 13 : 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (s.tmdb.releaseDate.isNotEmpty)
                                  Text(
                                    _formatDate(s.tmdb.releaseDate),
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                const SizedBox(width: 10),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  s.tmdb.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.suggestions.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? const Color(0xFF00E5FF)
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
