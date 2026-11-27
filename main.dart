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
          Text('ICC Men\'s ODI & T20I Rankings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ListTile(leading: CircleAvatar(child: Text('1')), title: Text('India'), subtitle: Text('T20I & ODI #1 Team'), trailing: Text('268', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: CircleAvatar(child: Text('2')), title: Text('Australia'), subtitle: Text('ODI #2 Team'), trailing: Text('257', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: CircleAvatar(child: Text('3')), title: Text('England'), subtitle: Text('T20I #3 Team'), trailing: Text('252', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(leading: CircleAvatar(child: Text('4')), title: Text('New Zealand'), subtitle: Text('Test Contender'), trailing: Text('246', style: TextStyle(fontWeight: FontWeight.bold))),
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
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailPage(match: m, allMatches: widget.all))),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: _cardDeco(14),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(shown.length.clamp(0, 8), (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i == _page % 8 ? 16 : 6, height: 6, decoration: BoxDecoration(color: i == _page % 8 ? const Color(0xFF312E81) : Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _pill('• Live (${widget.live.length})', () => setState(() => _tab = 1), Colors.red),
                  _pill('Fixtures', () => widget.onNav(2), Colors.black87),
                  _pill('Series', () => widget.onNav(3), Colors.black87),
                  _pill('Videos', () => widget.onNav(1), Colors.black87),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(14, 16, 14, 8), child: Text('Breaking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            ...news.map((n) => Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  padding: const EdgeInsets.all(10),
                  decoration: _cardDeco(12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(n.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(n.$2, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Container(width: 72, height: 54, decoration: BoxDecoration(color: n.$4, borderRadius: BorderRadius.circular(8)), child: Icon(n.$3, color: Colors.white, size: 26)),
                  ]),
                )),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: OutlinedButton(onPressed: () => widget.onNav(1), style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE5E7EB))), child: const Text('More Videos  ›', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600))),
            ),
            const Padding(padding: EdgeInsets.fromLTRB(14, 16, 14, 8), child: Text("ODI Men's Rankings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                _rankCard('#1 Batter', 'Shubman Gill', 'IND', const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                _rankCard('#1 Bowler', 'Rashid Khan', 'AFG', const Color(0xFF00897B)),
                const SizedBox(width: 8),
                _rankCard('#1 All-Rounder', 'A. Omarzai', 'AFG', const Color(0xFFC62828)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: OutlinedButton(onPressed: _openRankingsSheet, style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE5E7EB))), child: const Text('Open Rankings  ›', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.w600))),
            ),
            const Padding(padding: EdgeInsets.only(top: 22), child: Center(child: Text("India's quickest Cricket app", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD1D5DB))))),
          ],
        ),
      ),
    );
  }

  Widget _rankCard(String title, String name, String code, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: _cardDeco(12),
          child: Column(children: [
            Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600))),
            const SizedBox(height: 10),
            CircleAvatar(radius: 22, backgroundColor: c, child: Text(name.substring(0, 2).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(code, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          ]),
        ),
      );

  Widget _topTab(String t, bool sel, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: sel ? Colors.black : Colors.transparent, width: 2))), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sel ? Colors.black : Colors.grey))),
      );

  Widget _pill(String t, VoidCallback onTap, Color c) => GestureDetector(
        onTap: onTap,
        child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: _cardDeco(20), child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c))),
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

  String _crr = '-', _remLabel = 'Balls Rem', _remVal = '-', _sessionNote = '';
  String _pship = '-', _lastWkt = '-', _toss = '-', _yetToBat = '';
  String _oddsAB = '-', _oddsAL = '-', _oddsBB = '-', _oddsBL = '-', _oddsDB = '-', _oddsDL = '-';
  bool _hasDraw = false;
  String _sessTitle = 'Session', _sessB = '-', _sessL = '-', _rxbR = '-', _rxbB = '-';
  int _overNo = 1, _runs = 0, _ballsBowled = 0;
  List<String> _recent = [];
  List<Map<String, dynamic>> _batters = [], _allInnBat = [], _bowlers = [], _comm = [], _innings = [];

  @override
  void initState() {
    super.initState();
    _m = widget.match;
    _calcFallback();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleAuto() {
    setState(() {
      _auto1s = !_auto1s;
      if (_auto1s) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _load(fast: true));
      } else {
        _timer?.cancel();
      }
    });
  }

  void _calcFallback() {
    final s = (_m.scB != '-' && _m.scA == '-') ? _m.scB : (_m.scA != '-' ? _m.scA : _m.scB);
    final m = RegExp(r'(\d+)[/\-](\d+)\s*\((\d+(?:\.\d+)?)').firstMatch(s);
    final isTest = _m.fmt.toUpperCase().contains('TEST');
    if (m != null) {
      _runs = int.tryParse(m.group(1) ?? '') ?? 0;
      final ps = (m.group(3) ?? '0').split('.');
      final ov = int.tryParse(ps[0]) ?? 0;
      final bl = ps.length > 1 ? (int.tryParse(ps[1]) ?? 0) : 0;
      _ballsBowled = ov * 6 + bl;
      _overNo = bl == 0 && ov > 0 ? ov : ov + 1;
      final tot = ov + bl / 6.0;
      if (tot > 0) _crr = (_runs / tot).toStringAsFixed(2);
      if (isTest) {
        _remLabel = 'Over Rem';
        _remVal = '${(90 - ov).clamp(0, 90)}';
      } else {
        _remLabel = 'Balls Rem';
        final maxB = _m.fmt.toUpperCase().contains('ODI') ? 300 : 120;
        _remVal = '${(maxB - _ballsBowled).clamp(0, maxB)}';
      }
    }
    final om = RegExp(r'(\d+)\s*Over', caseSensitive: false).firstMatch(_sessTitle);
    final tr = int.tryParse(_sessL.split('.').first);
    if (om != null && tr != null) {
      final sb = (int.tryParse(om.group(1) ?? '') ?? 0) * 6;
      _rxbB = '${(sb - _ballsBowled).clamp(0, sb)}';
      _rxbR = '${(tr - _runs).clamp(0, 999)}';
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
            if (mo['teama'] is Map) { _oddsAB = '${mo['teama']['back'] ?? '-'}'; _oddsAL = '${mo['teama']['lay'] ?? '-'}'; }
            if (mo['teamb'] is Map) { _oddsBB = '${mo['teamb']['back'] ?? '-'}'; _oddsBL = '${mo['teamb']['lay'] ?? '-'}'; }
            if (mo['draw'] is Map && '${mo['draw']['back'] ?? ''}'.isNotEmpty) {
              _hasDraw = true;
              _oddsDB = '${mo['draw']['back']}';
              _oddsDL = '${mo['draw']['lay'] ?? '-'}';
            }
          }
          if (r['session_odds'] is List && (r['session_odds'] as List).isNotEmpty && (r['session_odds'] as List).first is Map) {
            final f = (r['session_odds'] as List).first as Map;
            _sessTitle = (f['title'] ?? 'Session').toString();
            _sessB = (f['back'] ?? f['yes'] ?? '-').toString();
            _sessL = (f['lay'] ?? f['no'] ?? '-').toString();
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
            listInn.add(im);
            lastInn = im;
            lastRes = b['response'] as Map;
          }
        }
      } catch (_) {}
    }

    if (lastInn != null && lastRes != null) {
      if (lastInn['equations'] is Map && (lastInn['equations']['runrate'] ?? '').toString().isNotEmpty) _crr = '${lastInn['equations']['runrate']}';
      if (lastInn['current_partnership'] is Map) _pship = '${lastInn['current_partnership']['runs'] ?? 0}(${lastInn['current_partnership']['balls'] ?? 0})';
      if (lastInn['last_wicket'] is Map && (lastInn['last_wicket']['name'] ?? '').toString().isNotEmpty) {
        _lastWkt = '${lastInn['last_wicket']['name']} ${lastInn['last_wicket']['runs'] ?? 0}(${lastInn['last_wicket']['balls'] ?? 0})';
      }
      final rs = (lastInn['recent_scores'] ?? '').toString().trim();
      if (rs.isNotEmpty) _recent = rs.split(RegExp(r'[,|\s]+')).where((s) => s.isNotEmpty).take(6).toList();
      if (lastInn['batsmen'] is List) {
        _allInnBat = (lastInn['batsmen'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        final now = _allInnBat.where((b) { final h = (b['how_out'] ?? '').toString().toLowerCase(); return h.isEmpty || h == 'not ou
