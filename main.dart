import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

const String kHost = 'cricket-live-line-advance.p.rapidapi.com';
const String kKey = 'ffd6c64576msh818c8b1946c397bp1ff264jsnf20b8376f8d7';
Map<String, String> get _hdr => {'x-rapidapi-host': kHost, 'x-rapidapi-key': kKey};

void main() => runApp(const CricketApp());

class CricketApp extends StatelessWidget {
  const CricketApp({super.key});
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
  final String id, title, shortTitle, subtitle, fmt, comp, statusStr, note, date, venue;
  final String tA, logoA, scA, tB, logoB, scB;
  final int code, latestInn;
  RapidMatch({
    required this.id, required this.title, required this.shortTitle, required this.subtitle,
    required this.fmt, required this.comp, required this.statusStr, required this.note,
    required this.date, required this.venue, required this.tA, required this.logoA,
    required this.scA, required this.tB, required this.logoB, required this.scB,
    required this.code, this.latestInn = 1,
  });

  factory RapidMatch.fromJson(Map<String, dynamic> j) {
    final c = j['competition'] is Map ? j['competition'] as Map : {};
    final v = j['venue'] is Map ? j['venue'] as Map : {};
    final a = j['teama'] is Map ? j['teama'] as Map : {};
    final b = j['teamb'] is Map ? j['teamb'] as Map : {};
    String sc(Map m) {
      final f = (m['scores_full'] ?? '').toString().trim();
      if (f.isNotEmpty) return f;
      final r = (m['scores'] ?? '').toString().trim();
      final o = (m['overs'] ?? '').toString().trim();
      return r.isNotEmpty ? (o.isNotEmpty ? '$r ($o)' : r) : '-';
    }
    final sa = sc(a), sb = sc(b);
    final vs = [(v['name'] ?? '').toString(), (v['location'] ?? '').toString()].where((s) => s.isNotEmpty).join(', ');
    return RapidMatch(
      id: (j['match_id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      shortTitle: (j['short_title'] ?? j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      fmt: (j['format_str'] ?? 'T20').toString(),
      comp: (c['title'] ?? '').toString(),
      statusStr: (j['status_str'] ?? '').toString(),
      note: (j['status_note'] ?? '').toString(),
      date: (j['date_start_ist'] ?? j['date_start'] ?? '').toString(),
      venue: vs.isEmpty ? 'TBA' : vs,
      tA: (a['short_name'] ?? a['name'] ?? 'T1').toString(),
      logoA: (a['logo_url'] ?? '').toString(),
      scA: sa,
      tB: (b['short_name'] ?? b['name'] ?? 'T2').toString(),
      logoB: (b['logo_url'] ?? '').toString(),
      scB: sb,
      code: int.tryParse((j['status'] ?? '1').toString()) ?? 1,
      latestInn: int.tryParse((j['latest_inning_number'] ?? '').toString()) ?? ((sa != '-' && sb != '-') ? 2 : 1),
    );
  }
}

Widget _logo(String url, String name, [double sz = 32]) {
  final ab = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  final fb = CircleAvatar(radius: sz / 2, backgroundColor: const Color(0xFFE3F2FD), child: Text(ab, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)));
  if (!url.startsWith('http')) return fb;
  return ClipOval(child: Image.network(url, width: sz, height: sz, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fb));
}

BoxDecoration _cardDeco([double r = 12]) => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r), border: Border.all(color: const Color(0xFFE5E7EB)));

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _nav = 0;
  bool _loading = false;
  List<RapidMatch> _live = [], _up = [], _done = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<List<RapidMatch>> _get(int st) async {
    final r = await http.get(Uri.https(kHost, '/matches', {'status': '$st', 'per_paged': '12', 'paged': '1'}), headers: _hdr).timeout(const Duration(seconds: 40));
    if (r.statusCode != 200) throw Exception('${r.statusCode}');
    final b = jsonDecode(r.body);
    if (b is Map && b['response'] is Map && b['response']['items'] is List) {
      return (b['response']['items'] as List).whereType<Map<String, dynamic>>().map(RapidMatch.fromJson).toList();
    }
    return [];
  }

  Future<void> _loadAll() async {
    if (mounted) setState(() => _loading = true);
    try { final l = await _get(3); if (mounted) setState(() { _live = l; _loading = false; }); } catch (_) { if (mounted) setState(() => _loading = false); }
    try { final u = await _get(1); if (mounted) setState(() => _up = u); } catch (_) {}
    try { final d = await _get(2); if (mounted) setState(() => _done = d); } catch (_) {}
  }

  List<RapidMatch> get _all => [..._live, ..._up, ..._done];

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeScreen(live: _live, up: _up, done: _done, all: _all, loading: _loading, onRefresh: _loadAll, onNav: (i) => setState(() => _nav = i)),
      const _FlicksScreen(),
      _FixturesScreen(all: _all),
      _SeriesScreen(all: _all),
      _MoreScreen(onNav: (i) => setState(() => _nav = i)),
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

class _HomeScreen extends StatefulWidget {
  final List<RapidMatch> live, up, done, all;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onNav;
  const _HomeScreen({required this.live, required this.up, required this.done, required this.all, required this.loading, required this.onRefresh, required this.onNav});
  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _tab = 0, _page = 0;

  void _openRankingsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text("ICC Men's ODI & T20I Rankings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ListTile(leading: CircleAvatar(child: Text('1')), title: Text('India'), subtitle: Text('T20I & ODI #1 Team'), trailing: Text('268', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: CircleAvatar(child: Text('2')), title: Text('Australia'), subtitle: Text('ODI #2 Team'), trailing: Text('257', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: CircleAvatar(child: Text('3')), title: Text('England'), subtitle: Text('T20I #3 Team'), trailing: Text('252', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final featured = [...widget.live, ...widget.up.take(4), ...widget.done.take(4)];
    final shown = _tab == 0 ? featured : widget.live;
    final news = [
      ('India vs New Zealand 2nd Test: Day 1 Stumps Report', '6 hrs ago', Icons.sports_cricket, Color(0xFF1565C0)),
      ('IPL 2027 Mega Retention & Squad Updates Announced', '1 day ago', Icons.emoji_events, Color(0xFFC62828)),
      ('ILT20 League: MI Emirates vs Gulf Giants Thriller', '2 days ago', Icons.flash_on, Color(0xFF00897B)),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 6),
              child: Row(children: [
                const Icon(Icons.sports_cricket, size: 22),
                const SizedBox(width: 8),
                const Text('Cricket Fast Live', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: widget.loading ? null : widget.onRefresh, icon: widget.loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 20)),
              ]),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                _topTab('Featured', _tab == 0, () => setState(() => _tab = 0)),
                const SizedBox(width: 18),
                _topTab('Live (${widget.live.length})', _tab == 1, () => setState(() => _tab = 1)),
              ]),
            ),
            const SizedBox(height: 10),
            if (shown.isEmpty)
              Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(24), decoration: _cardDeco(), child: Center(child: Text(widget.loading ? 'Loading live matches...' : 'Koi match nahi mila. Pull to refresh.')))
            else ...[
              SizedBox(
                height: 158,
                child: PageView.builder(
                  itemCount: shown.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final m = shown[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, Materia
