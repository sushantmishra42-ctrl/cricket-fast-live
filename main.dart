import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String kRapidApiHost = 'cricket-live-line-advance.p.rapidapi.com';
const String kRapidApiKey = 'ffd6c64576msh818c8b1946c397bp1ff264jsnf20b8376f8d7';

Map<String, String> get _headers => {'x-rapidapi-host': kRapidApiHost, 'x-rapidapi-key': kRapidApiKey};

void main() => runApp(const CricketGuruApp());

class CricketGuruApp extends StatelessWidget {
  const CricketGuruApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cricket Fast Live',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: const ColorScheme.light(primary: Color(0xFF00897B), secondary: Color(0xFFD81B60), surface: Colors.white),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      ),
      home: const MainShell(),
    );
  }
}

class RapidMatch {
  final String matchId, title, shortTitle, subtitle, formatStr, competition, statusStr, statusNote, dateStartIst, venue;
  final String teamA, teamALogo, teamAScore, teamB, teamBLogo, teamBScore;
  final int statusCode, latestInning;

  RapidMatch({
    required this.matchId, required this.title, required this.shortTitle, required this.subtitle,
    required this.formatStr, required this.competition, required this.statusStr, required this.statusNote,
    required this.dateStartIst, required this.venue, required this.teamA, required this.teamALogo,
    required this.teamAScore, required this.teamB, required this.teamBLogo, required this.teamBScore,
    required this.statusCode, this.latestInning = 1,
  });

  factory RapidMatch.fromJson(Map<String, dynamic> j) {
    final comp = j['competition'] is Map ? j['competition'] as Map : {};
    final ven = j['venue'] is Map ? j['venue'] as Map : {};
    final ta = j['teama'] is Map ? j['teama'] as Map : {};
    final tb = j['teamb'] is Map ? j['teamb'] as Map : {};

    String scoreOf(Map t) {
      final full = (t['scores_full'] ?? '').toString().trim();
      if (full.isNotEmpty) return full;
      final sc = (t['scores'] ?? '').toString().trim();
      final ov = (t['overs'] ?? '').toString().trim();
      return sc.isNotEmpty ? (ov.isNotEmpty ? '$sc ($ov)' : sc) : '-';
    }

    final sA = scoreOf(ta), sB = scoreOf(tb);
    final vStr = [(ven['name'] ?? '').toString(), (ven['location'] ?? '').toString()].where((s) => s.isNotEmpty).join(', ');
    return RapidMatch(
      matchId: (j['match_id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      shortTitle: (j['short_title'] ?? j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      formatStr: (j['format_str'] ?? 'T20').toString(),
      competition: (comp['title'] ?? '').toString(),
      statusStr: (j['status_str'] ?? '').toString(),
      statusNote: (j['status_note'] ?? '').toString(),
      dateStartIst: (j['date_start_ist'] ?? j['date_start'] ?? '').toString(),
      venue: vStr.isEmpty ? 'TBA' : vStr,
      teamA: (ta['short_name'] ?? ta['name'] ?? 'Team A').toString(),
      teamALogo: (ta['logo_url'] ?? '').toString(),
      teamAScore: sA,
      teamB: (tb['short_name'] ?? tb['name'] ?? 'Team B').toString(),
      teamBLogo: (tb['logo_url'] ?? '').toString(),
      teamBScore: sB,
      statusCode: int.tryParse((j['status'] ?? '1').toString()) ?? 1,
      latestInning: int.tryParse((j['latest_inning_number'] ?? '').toString()) ?? ((sA != '-' && sB != '-') ? 2 : 1),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _nav = 0;
  bool _loading = false;
  List<RapidMatch> _live = [], _upcoming = [], _finished = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<List<RapidMatch>> _getMatches(int st) async {
    final res = await http.get(Uri.https(kRapidApiHost, '/matches', {'status': '$st', 'per_paged': '12', 'paged': '1'}), headers: _headers).timeout(const Duration(seconds: 40));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final b = jsonDecode(res.body);
    if (b is Map && b['response'] is Map && b['response']['items'] is List) {
      return (b['response']['items'] as List).whereType<Map<String, dynamic>>().map(RapidMatch.fromJson).toList();
    }
    return [];
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _loading = true);
    try { final l = await _getMatches(3); if (mounted) setState(() { _live = l; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); }
    try { final u = await _getMatches(1); if (mounted) setState(() => _upcoming = u); } catch (_) {}
    try { final f = await _getMatches(2); if (mounted) setState(() => _finished = f); } catch (_) {}
  }

  List<RapidMatch> get _all => [..._live, ..._upcoming, ..._finished];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(live: _live, upcoming: _upcoming, finished: _finished, loading: _loading, onRefresh: _loadAll, allMatches: _all, onTabJump: (i) => setState(() => _nav = i)),
      const FlicksTab(),
      FixturesTab(live: _live, upcoming: _upcoming, finished: _finished, allMatches: _all),
      SeriesTab(allMatches: _all),
      MoreTab(onJump: (i) => setState(() => _nav = i)),
    ];

    return Scaffold(
      body: pages[_nav],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _nav,
        onTap: (i) => setState(() => _nav = i),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Flicks'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: 'Fixtures'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Series'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String url, name;
  final double size;
  const _TeamLogo({required this.url, required this.name, this.size = 34});
  @override
  Widget build(BuildContext context) {
    final abbr = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    if (url.startsWith('http')) {
      return ClipOval(
        child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CircleAvatar(radius: size / 2, backgroundColor: const Color(0xFFE3F2FD), child: Text(abbr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black))),
        ),
      );
    }
    return CircleAvatar(radius: size / 2, backgroundColor: const Color(0xFFE3F2FD), child: Text(abbr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)));
  }
}

class HomeTab extends StatefulWidget {
  final List<RapidMatch> live, upcoming, finished, allMatches;
  final bool loading;
  final Future<void> Function() onRefresh;
