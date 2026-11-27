import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

BoxDecoration _card([double r = 12]) => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(r), border: Border.all(color: const Color(0xFFE5E7EB)));

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
  void initState() { super.initState(); _loadAll(); }

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

  @override
  Widget build(BuildContext context) {
    final featured = [...widget.live, ...widget.up.take(4), ...widget.done.take(4)];
    final shown = _tab == 0 ? featured : widget.live;
    final seriesName = widget.all.map((m) => m.comp).where((s) => s.isNotEmpty).firstOrNull ?? 'International & T20 Leagues';
    final news = [
      ('India dominate with strong total on Day 1', '2 hrs ago', const Color(0xFF1E3A8A)),
      ('IPL & T20 Leagues: Key player milestones', '6 hrs ago', const Color(0xFF065F46)),
      ('Upcoming Test & ODI schedule updates', '1 day ago', const Color(0xFF7C2D12)),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 4),
              child: Row(children: [
                const Icon(Icons.sports_cricket, size: 22),
                const SizedBox(width: 8),
                const Text('Cricket Fast Live', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => widget.onNav(2), icon: const Icon(Icons.search, size: 21)),
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
              Container(margin: const EdgeInsets.all(14), padding: const EdgeInsets.all(24), decoration: _card(), child: Center(child: Text(widget.loading ? 'Loading matches...' : 'Koi match nahi mila.')))
            else ...[
              SizedBox(
                height: 158,
                child: PageView.builder(
                  itemCount: shown.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final m = shown[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailPage(match: m, allMatches: widget.all))),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: _card(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text('${m.comp.isNotEmpty ? m.comp : m.title}${m.subtitle.isNotEmpty ? ", ${m.subtitle}" : ""}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ]),
                          Text(m.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const Spacer(),
                          Row(children: [
                            _logo(m.logoA, m.tA, 34),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(m.scA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis), Text(m.tA, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
                            Text(m.code == 3 ? '• Live' : (m.code == 2 ? 'Finished' : 'Upcoming'), style: TextStyle(color: m.code == 3 ? Colors.red : const Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 11)),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(m.scB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis), Text(m.tB, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])),
                            const SizedBox(width: 8),
                            _logo(m.logoB, m.tB, 34),
                          ]),
                          const Spacer(),
                          Row(children: [
                            Expanded(child: Text(m.note.isNotEmpty ? m.note : m.venue, style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.bar_chart, size: 16, color: Colors.black54),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(shown.length.clamp(0, 8), (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _page % 8 ? 16 : 6, height: 6, decoration: BoxDecoration(color: i == _page % 8 ? const Color(0xFF312E81) : Colors.grey.shade300, borderRadius: BorderRadius.circular(4))))),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                _pill('• Live (${widget.live.length})', () => setState(() => _tab = 1), Colors.red),
                _pill('Fixtures', () => widget.onNav(2), Colors.black87),
                _pill('Series', () => widget.onNav(3), Colors.black87),
                _pill('Videos', () => widget.onNav(1), Colors.black87),
              ]),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(14, 14, 14, 8), child: Text('Trending Series', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            GestureDetector(
              onTap: () => widget.onNav(3),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: _card(),
                child: Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.emoji_events, color: Colors.amber)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(seriesName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), Text('${widget.all.length} Matches • Live & Upcoming', style: const TextStyle(color: Colors.grey, fontSize: 12))])),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ]),
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(14, 16, 14, 8), child: Text('Breaking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ...news.map((n) => Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: _card(),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(n.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), const SizedBox(height: 6), Text(n.$2, style: const TextStyle(color: Colors.grey, fontSize: 11))])),
                    const SizedBox(width: 10),
                    Container(width: 68, height: 54, decoration: BoxDecoration(color: n.$3, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.sports_cricket, color: Colors.white)),
                  ]),
                )),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              width: double.infinity,
              child: OutlinedButton(onPressed: () => widget.onNav(1), style: OutlinedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('More Videos ›', style: TextStyle(color: Color(0xFF312E81), fontWeight: FontWeight.w600))),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(14, 0, 14, 8), child: Text("ODI Men's Rankings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                _rankCard('#1 Batter', 'Shubman Gill', 'IND', const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _rankCard('#1 Bowler', 'Rashid Khan', 'AFG', const Color(0xFF059669)),
                const SizedBox(width: 8),
                _rankCard('#1 All-Rounder', 'A. Omarzai', 'AFG', const Color(0xFFDC2626)),
              ]),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              width: double.infinity,
              child: OutlinedButton(onPressed: () => widget.onNav(4), style: OutlinedButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Open Rankings ›', style: TextStyle(color: Color(0xFF312E81), fontWeight: FontWeight.w600))),
            ),
            const Center(child: Text("India's quickest Cricket app", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFCBD5E1)))),
          ],
        ),
      ),
    );
  }

  Widget _rankCard(String role, String name, String ctry, Color col) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: _card(12),
          child: Column(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)), child: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 8),
            CircleAvatar(radius: 22, backgroundColor: col, child: Text(name.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(ctry, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  Widget _topTab(String t, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? Colors.black : Colors.transparent, width: 2))), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sel ? Colors.black : Colors.grey))),
      );

  Widget _pill(String t, VoidCallback onTap, Color c) => GestureDetector(
        onTap: onTap,
        child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: _card(20), child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
      );
}

class MatchDetailPage extends StatefulWidget {
  final RapidMatch match;
  final List<RapidMatch> allMatches;
  const MatchDetailPage({super.key, required this.match, required this.allMatches});
  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  bool _loading = false, _fetching = false, _auto1s = false, _voice = false, _innOpen = false;
  Timer? _timer;
  late RapidMatch _m;

  String _crr = '-', _rrr = '-', _remText = '-', _target = '-', _pship = '-', _lastWkt = '-', _toss = '-';
  String _backA = '-', _layA = '-', _backB = '-', _layB = '-', _backDraw = '-', _layDraw = '-';
  String _sessTitle = 'Session', _sessB = '-', _sessL = '-', _rxbR = '-', _rxbB = '-', _yetToBat = '';
  int _overNo = 1;
  List<String> _recent = [];
  List<Map<String, dynamic>> _batters = [], _allInnBat = [], _bowlers = [], _comm = [], _innings = [];

  @override
  void initState() { super.initState(); _m = widget.match; _calcFallback(); _load(); }
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _toggleAuto() {
    setState(() {
      _auto1s = !_auto1s;
      if (_auto1s) { _timer = Timer.periodic(const Duration(seconds: 1), (_) => _load(fast: true)); }
      else { _timer?.cancel(); }
    });
  }

  void _calcFallback() {
    final s = (_m.scB != '-' && _m.scA == '-') ? _m.scB : (_m.scA != '-' ? _m.scA : _m.scB);
    final m = RegExp(r'(\d+)[/\-](\d+)\s*\((\d+(?:\.\d+)?)').firstMatch(s);
    if (m != null) {
      final runs = int.tryParse(m.group(1) ?? '') ?? 0;
      final ps = (m.group(3) ?? '0').split('.');
      final ov = int.tryParse(ps[0]) ?? 0;
      final bl = ps.length > 1 ? (int.tryParse(ps[1]) ?? 0) : 0;
      final tot = ov + bl / 6.0;
      if (tot > 0) _crr = (runs / tot).toStringAsFixed(2);
      _overNo = bl == 0 && ov > 0 ? ov : ov + 1;
      if (_m.fmt.toUpperCase().contains('TEST')) {
        _remText = 'Over Rem: ${(90 - ov).clamp(0, 90)}';
      } else {
        final maxB = _m.fmt.toUpperCase().contains('ODI') ? 300 : 120;
        _remText = 'Balls Rem: ${(maxB - (ov * 6 + bl)).clamp(0, maxB)}';
      }
    }
  }

  Future<void> _load({bool fast = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!fast && mounted) setState(() => _loading = true);
    int maxInn = _m.latestInn.clamp(1, 2);

    try {
      final ir = await http.get(Uri.https(kHost, '/matches/${_m.id}/info'), headers: _hdr).timeout(const Duration(seconds: 25));
      if (ir.statusCode == 200) {
        final b = jsonDecode(ir.body);
        if (b is Map && b['response'] is Map) {
          final r = b['response'] as Map;
          _m = RapidMatch.fromJson(Map<String, dynamic>.from(r));
          maxInn = _m.latestInn.clamp(1, 2);
          if (r['toss'] is Map && (r['toss']['text'] ?? '').toString().isNotEmpty) _toss = r['toss']['text'].toString();
          if (r['live_odds'] is Map && r['live_odds']['matchodds'] is Map) {
            final mo = r['live_odds']['matchodds'] as Map;
            if (mo['teama'] is Map) { _backA = '${mo['teama']['back'] ?? '-'}'; _layA = '${mo['teama']['lay'] ?? '-'}'; }
            if (mo['teamb'] is Map) { _backB = '${mo['teamb']['back'] ?? '-'}'; _layB = '${mo['teamb']['lay'] ?? '-'}'; }
            if (mo['draw'] is Map) { _backDraw = '${mo['draw']['back'] ?? '-'}'; _layDraw = '${mo['draw']['lay'] ?? '-'}'; }
          }
          if (r['session_odds'] is List && (r['session_odds'] as List).isNotEmpty && (r['session_odds'] as List).first is Map) {
            final f = (r['session_odds'] as List).first as Map;
            _sessTitle = (f['title'] ?? 'Session').toString();
            _sessB = '${f['back'] ?? f['yes'] ?? '-'}';
            _sessL = '${f['lay'] ?? f['no'] ?? '-'}';
          }
        }
      }
    } catch (_) {}

    final listInn = <Map<String, dynamic>>[];
    Map<String, dynamic>? lastInn;
    Map? lastRes;
    for (int n = (fast ? maxInn : 1); n <= maxInn; n++) {
      try {
        final cr = await http.get(Uri.https(kHost, '/matches/${_m.id}/innings/$n/commentary'), headers: _hdr).timeout(const Duration(seconds: 25));
        if (cr.statusCode == 200) {
          final b = jsonDecode(cr.body);
          if (b is Map && b['response'] is Map && b['response']['inning'] is Map) {
            final im = Map<String, dynamic>.from(b['response']['inning'] as Map);
            listInn.add(im); lastInn = im; lastRes = b['response'] as Map;
          }
        }
      } catch (_) {}
    }

    if (lastInn != null && lastRes != null) {
      if (lastInn['equations'] is Map) {
        final eq = lastInn['equations'] as Map;
        if ((eq['runrate'] ?? '').toString().isNotEmpty) _crr = '${eq['runrate']}';
        if ((eq['required_runrate'] ?? '').toString().isNotEmpty) _rrr = '${eq['required_runrate']}';
        if (maxInn >= 2 && (eq['target'] ?? '0').toString() != '0') _target = '${eq['target']}';
      }
      if (lastInn['current_partnership'] is Map) _pship = '${lastInn['current_partnership']['runs'] ?? 0}(${lastInn['current_partnership']['balls'] ?? 0})';
      if (lastInn['last_wicket'] is Map && (lastInn['last_wicket']['name'] ?? '').toString().isNotEmpty) _lastWkt = '${lastInn['last_wicket']['name']} ${lastInn['last_wicket']['runs'] ?? 0}(${lastInn['last_wicket']['balls'] ?? 0})';
      final rs = (lastInn['recent_scores'] ?? '').toString().trim();
      if (rs.isNotEmpty) _recent = rs.split(RegExp(r'[,|\s]+')).where((s) => s.isNotEmpty).take(6).toList();
      if (lastInn['batsmen'] is List) {
        _allInnBat = (lastInn['batsmen'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        final now = _allInnBat.where((b) { final h = (b['how_out'] ?? '').toString().toLowerCase(); return h.isEmpty || h == 'not out'; }).toList();
        _batters = now.isNotEmpty ? now : _allInnBat.take(2).toList();
      }
      if (lastInn['bowlers'] is List) {
        final ab = (lastInn['bowlers'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        final bn = ab.where((w) => w['bowling'] == true || w['bowling'] == 'true').toList();
        _bowlers = bn.isNotEmpty ? bn : (ab.isNotEmpty ? [ab.last] : []);
      }
      if (lastInn['did_not_bat'] is List) _yetToBat = (lastInn['did_not_bat'] as List).whereType<Map>().map((e) => (e['name'] ?? '').toString()).where((s) => s.isNotEmpty).join(', ');
      if (lastRes['commentaries'] is List) _comm = (lastRes['commentaries'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList().reversed.toList();
    }

    if (!fast && listInn.isNotEmpty) _innings = listInn;
    _calcFallback();
    _fetching = false;
    if (mounted) setState(() => _loading = false);
  }

  void _openSwitcher() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(12),
        children: widget.allMatches.take(12).map((m) => ListTile(
          leading: _logo(m.logoA, m.tA, 28),
          title: Text(m.shortTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: Text('${m.scA} | ${m.scB}', style: const TextStyle(fontSize: 11)),
          trailing: Text(m.code == 3 ? '• Live' : (m.code == 2 ? 'Finished' : 'Upcoming'), style: TextStyle(color: m.code == 3 ? Colors.red : Colors.grey, fontSize: 11)),
          onTap: () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MatchDetailPage(match: m, allMatches: widget.allMatches))); },
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          title: GestureDetector(
            onTap: _openSwitcher,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Text(_m.shortTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, size: 20)]),
              if (_m.subtitle.isNotEmpty) Text(_m.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          actions: [
            TextButton(onPressed: _toggleAuto, child: Text(_auto1s ? 'Auto 1s ON' : 'Auto 1s', style: TextStyle(color: _auto1s ? const Color(0xFFD81B60) : const Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 12))),
            IconButton(onPressed: _loading ? null : () => _load(), icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 20)),
          ],
          bottom: const TabBar(isScrollable: true, labelColor: Colors.black, unselectedLabelColor: Colors.grey, indicatorColor: Colors.black, labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), tabs: [Tab(text: 'Info'), Tab(text: 'Live'), Tab(text: 'Commentary'), Tab(text: 'Scorecard'), Tab(text: 'History')]),
        ),
        body: TabBarView(children: [_infoTab(), _liveTab(), _commTab(), _scorecardTab(), _historyTab()]),
      ),
    );
  }

  Widget _infoTab() => ListView(padding: const EdgeInsets.all(10), children: [
        Container(padding: const EdgeInsets.all(14), decoration: _card(), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Column(children: [_logo(_m.logoA, _m.tA, 40), const SizedBox(height: 6), Text(_m.tA, style: const TextStyle(fontWeight: FontWeight.bold))]),
          const Icon(Icons.bolt, color: Colors.amber, size: 26),
          Column(children: [_logo(_m.logoB, _m.tB, 40), const SizedBox(height: 6), Text(_m.tB, style: const TextStyle(fontWeight: FontWeight.bold))]),
        ])),
        const SizedBox(height: 8),
        _tile('Series', _m.comp.isEmpty ? _m.title : _m.comp),
        _tile('Date & Time', _m.date),
        _tile('Toss', _toss),
        _tile('Venue', _m.venue),
      ]);

  Widget _liveTab() {
    final topScore = _m.scB != '-' ? '${_m.tB} ${_m.scB}' : '${_m.tA} ${_m.scA}';
    final innLabel = _m.scB != '-' ? '1st Innings - ${_m.tB}' : '1st Innings - ${_m.tA}';
    final isTest = _m.fmt.toUpperCase().contains('TEST') || _backDraw != '-';

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          color: Colors.white,
          child: Column(children: [
            Container(
              height: 92, color: Colors.black, padding: const EdgeInsets.all(12),
              child: Stack(children: [
                Align(alignment: Alignment.topLeft, child: GestureDetector(onTap: () => setState(() => _voice = !_voice), child: Icon(_voice ? Icons.volume_up : Icons.volume_off, color: Colors.white, size: 18))),
                Align(alignment: Alignment.topRight, child: Text(_m.code == 3 ? '• Live' : _m.statusStr, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))),
                Center(child: Text(_m.note.isNotEmpty ? _m.note : topScore, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(topScore, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (_m.scA != '-' && _m.scB != '-') Text('${_m.tA} ${_m.scA}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54)),
              ]),
            ),
          ]),
        ),
        if (_recent.isNotEmpty)
          Container(margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: _card(8), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [Text('Over $_overNo  ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), ..._recent.map(_ball)]))),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), padding: const EdgeInsets.all(10), decoration: _card(8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('CRR: $_crr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(_remText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            if (_target != '-') Text('Target: $_target', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), padding: const EdgeInsets.all(10), decoration: _card(8),
          child: isTest
              ? Column(children: [
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.info_outline, size: 15, color: Colors.grey), SizedBox(width: 5), Text('Win Probability', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500))]),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _probCol(_m.tA, _backA, _layA),
                    _probCol(_m.tB, _backB, _layB),
                    _probCol('DRAW', _backDraw, _layDraw),
                  ]),
                ])
              : Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Win Probability', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Row(children: [Text('${_backA != '-' ? _m.tA : _m.tB}: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)), _rate(_backA != '-' ? _backA : _backB, true), const SizedBox(width: 4), _rate(_layA != '-' ? _layA : _layB, false)]),
                  ]),
                  const Divider(height: 14, color: Color(0xFFEEEEEE)),
                  FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Text('$_sessTitle: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), _rate(_sessB, true), const SizedBox(width: 4), _rate(_sessL, false), const SizedBox(width: 14), const Text('R X B: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)), _rate(_rxbR, true), const SizedBox(width: 4), _rate(_rxbB, false)])),
                ]),
        ),
        if (_batters.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), padding: const EdgeInsets.all(10), decoration: _card(8),
            child: Column(children: [
              const Row(children: [Expanded(flex: 5, child: Text('Batter', style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))), Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11)))]),
              const Divider(),
              ..._batters.asMap().entries.map((e) {
                final b = e.value;
                return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                  Expanded(flex: 5, child: Row(children: [Flexible(child: Text('${b['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis)), if (e.key == 0) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.sports_cricket, size: 13, color: Color(0xFFC58B2B)))])),
                  Expanded(child: Text('${b['runs'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(child: Text('${b['balls_faced'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  Expanded(child: Text('${b['fours'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  Expanded(child: Text('${b['sixes'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text('${b['strike_rate'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                ]));
              }),
              const Divider(),
              FittedBox(fit: BoxFit.scaleDown, child: Row(children: [Text("P'ship: $_pship", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)), const SizedBox(width: 14), Text("L' Wkt: $_lastWkt", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])),
            ]),
          ),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0), padding: const EdgeInsets.all(10), decoration: _card(8),
          child: Column(children: [
            const Row(children: [Expanded(flex: 5, chi
