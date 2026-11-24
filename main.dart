import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kRapidApiHost = 'cricket-live-line-advance.p.rapidapi.com';
const String kRapidApiKey = 'ffd6c64576msh818c8b1946c397bp1ff264jsnf20b8376f8d7';

Map<String, String> get _apiHeaders => {
      'x-rapidapi-host': kRapidApiHost,
      'x-rapidapi-key': kRapidApiKey,
    };

void main() {
  runApp(const CricketLiveLineApp());
}

class CricketLiveLineApp extends StatelessWidget {
  const CricketLiveLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cricket Fast Live',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00897B),
          secondary: Color(0xFFD81B60),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const MainShell(),
    );
  }
}

class RapidMatch {
  final String matchId;
  final String title;
  final String shortTitle;
  final String subtitle;
  final String formatStr;
  final String competition;
  final String statusStr;
  final String statusNote;
  final String dateStartIst;
  final String venue;
  final String teamA;
  final String teamAScore;
  final String teamB;
  final String teamBScore;
  final int statusCode;

  RapidMatch({
    required this.matchId,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.formatStr,
    required this.competition,
    required this.statusStr,
    required this.statusNote,
    required this.dateStartIst,
    required this.venue,
    required this.teamA,
    required this.teamAScore,
    required this.teamB,
    required this.teamBScore,
    required this.statusCode,
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
      if (sc.isNotEmpty) return ov.isNotEmpty ? '$sc ($ov)' : sc;
      return '-';
    }

    final vName = (ven['name'] ?? '').toString();
    final vLoc = (ven['location'] ?? '').toString();
    final venueStr = [vName, vLoc].where((s) => s.isNotEmpty).join(', ');

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
      venue: venueStr.isEmpty ? 'TBA' : venueStr,
      teamA: (ta['short_name'] ?? ta['name'] ?? 'Team A').toString(),
      teamAScore: scoreOf(ta),
      teamB: (tb['short_name'] ?? tb['name'] ?? 'Team B').toString(),
      teamBScore: scoreOf(tb),
      statusCode: int.tryParse((j['status'] ?? '1').toString()) ?? 1,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pages = <Widget>[
      HomeMatchesTab(),
      SeriesTab(),
      RankingsTab(),
      NewsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.sports_cricket, color: Color(0xFFFFD54F), size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Cricket Fast Live', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFDE8EC), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFFD81B60), size: 8),
                SizedBox(width: 5),
                Text('LIVE LINE', style: TextStyle(color: Color(0xFFD81B60), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: pages[_navIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF00897B),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Series'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'Rankings'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
        ],
      ),
    );
  }
}

class HomeMatchesTab extends StatefulWidget {
  const HomeMatchesTab({super.key});

  @override
  State<HomeMatchesTab> createState() => _HomeMatchesTabState();
}

class _HomeMatchesTabState extends State<HomeMatchesTab> {
  bool _loading = false;
  String? _bannerMsg;
  List<RapidMatch> _live = [];
  List<RapidMatch> _upcoming = [];
  List<RapidMatch> _finished = [];

  @override
  void initState() {
    super.initState();
    _fetchAllMatches();
  }

  Future<List<RapidMatch>> _fetchByStatus(int status) async {
    final uri = Uri.https(kRapidApiHost, '/matches', {
      'status': '$status',
      'per_paged': '10',
      'paged': '1',
    });
    final res = await http.get(uri, headers: _apiHeaders).timeout(const Duration(seconds: 40));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body is Map && body['response'] is Map && body['response']['items'] is List) {
      return (body['response']['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => RapidMatch.fromJson(e))
          .toList();
    }
    return [];
  }

  Future<void> _fetchAllMatches() async {
    setState(() {
      _loading = true;
      _bannerMsg = null;
    });

    try {
      final liveList = await _fetchByStatus(3);
      if (!mounted) return;
      setState(() {
        _live = liveList;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _bannerMsg = 'Live load issue ($e). Refresh dabayein.';
      });
    }

    try {
      final upList = await _fetchByStatus(1);
      if (mounted) setState(() => _upcoming = upList);
    } catch (_) {}

    try {
      final doneList = await _fetchByStatus(2);
      if (mounted) setState(() => _finished = doneList);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Row(
              children: [
                const Expanded(
                  child: TabBar(
                    indicatorColor: Colors.black,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: [
                      Tab(text: 'LIVE'),
                      Tab(text: 'UPCOMING'),
                      Tab(text: 'FINISHED'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _fetchAllMatches,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
          if (_bannerMsg != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8E1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(_bannerMsg!, style: const TextStyle(fontSize: 11, color: Color(0xFF8D6E00))),
            ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(_live, 'Abhi koi Live match nahi chal raha.'),
                _buildList(_upcoming, 'Upcoming matches load ho rahe hain...'),
                _buildList(_finished, 'Finished matches load ho rahe hain...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<RapidMatch> list, String emptyText) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAllMatches,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(_loading ? 'Matches load ho rahe hain (5-10 sec)...' : emptyText, style: const TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final m = list[i];
          final isLive = m.statusCode == 3;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LiveMatchDetailPage(match: m)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${m.formatStr} • ${m.competition.isNotEmpty ? m.competition : m.subtitle}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFFFDE8EC) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isLive ? '• Live' : (m.statusCode == 2 ? 'Result' : 'Upcoming'),
                          style: TextStyle(
                            color: isLive ? const Color(0xFFD81B60) : Colors.black54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(m.teamA, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      Text(m.teamAScore, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(m.teamB, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      Text(m.teamBScore, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFEEEEEE)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          m.statusNote.isNotEmpty ? m.statusNote : (m.dateStartIst.isNotEmpty ? m.dateStartIst : m.venue),
                          style: const TextStyle(color: Color(0xFFD81B60), fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text('Live Line ›', style: TextStyle(color: Color(0xFF00897B), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
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

class LiveMatchDetailPage extends StatefulWidget {
  final RapidMatch match;
  const LiveMatchDetailPage({super.key, required this.match});

  @override
  State<LiveMatchDetailPage> createState() => _LiveMatchDetailPageState();
}

class _LiveMatchDetailPageState extends State<LiveMatchDetailPage> {
  bool _loading = false;
  bool _autoLive = false;
  Timer? _timer;
  late RapidMatch _m;

  String _crr = '-';
  String _rrr = '-';
  String _target = '-';
  String _pship = '-';
  String _lastWkt = '-';
  String _toss = '-';
  String _oddsTeam = '';
  String _oddsBack = '-';
  String _oddsLay = '-';
  String _sessionTitle = 'Session';
  String _sessionBack = '-';
  String _sessionLay = '-';
  List<String> _recentBalls = [];
  List<Map<String, dynamic>> _batters = [];
  List<Map<String, dynamic>> _bowlers = [];
  List<Map<String, dynamic>> _commentary = [];
  List<Map<String, dynamic>> _scorecardInnings = [];

  @override
  void initState() {
    super.initState();
    _m = widget.match;
    _loadLiveAndScorecard();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleAuto() {
    setState(() {
      _autoLive = !_autoLive;
      if (_autoLive) {
        _timer = Timer.periodic(const Duration(seconds: 15), (_) => _loadLiveAndScorecard());
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _loadLiveAndScorecard() async {
    setState(() => _loading = true);
    try {
      final liveUri = Uri.https(kRapidApiHost, '/matches/${_m.matchId}/live');
      final liveRes = await http.get(liveUri, headers: _apiHeaders).timeout(const Duration(seconds: 30));
      if (liveRes.statusCode == 200) {
        final body = jsonDecode(liveRes.body);
        if (body is Map && body['response'] is Map) {
          _parseLiveResponse(body['response'] as Map);
        }
      }

      final scUri = Uri.https(kRapidApiHost, '/matches/${_m.matchId}/scorecard');
      final scRes = await http.get(scUri, headers: _apiHeaders).timeout(const Duration(seconds: 30));
      if (scRes.statusCode == 200) {
        final body = jsonDecode(scRes.body);
        if (body is Map && body['response'] is Map) {
          final r = body['response'] as Map;
          if (r['toss'] is Map && (r['toss']['text'] ?? '').toString().isNotEmpty) {
            _toss = r['toss']['text'].toString();
          }
          if (r['innings'] is List) {
            _scorecardInnings = (r['innings'] as List).whereType<Map<String, dynamic>>().toList();
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _parseLiveResponse(Map r) {
    if (r['teama'] is Map || r['teamb'] is Map) {
      _m = RapidMatch(
        matchId: _m.matchId,
        title: (r['title'] ?? _m.title).toString(),
        shortTitle: _m.shortTitle,
        subtitle: _m.subtitle,
        formatStr: _m.formatStr,
        competition: _m.competition,
        statusStr: (r['status_str'] ?? _m.statusStr).toString(),
        statusNote: (r['status_note'] ?? _m.statusNote).toString(),
        dateStartIst: _m.dateStartIst,
        venue: _m.venue,
        teamA: (r['teama'] is Map ? (r['teama']['short_name'] ?? _m.teamA) : _m.teamA).toString(),
        teamAScore: (r['teama'] is Map ? (r['teama']['scores_full'] ?? _m.teamAScore) : _m.teamAScore).toString(),
        teamB: (r['teamb'] is Map ? (r['teamb']['short_name'] ?? _m.teamB) : _m.teamB).toString(),
        teamBScore: (r['teamb'] is Map ? (r['teamb']['scores_full'] ?? _m.teamBScore) : _m.teamBScore).toString(),
        statusCode: _m.statusCode,
      );
    }

    if (r['batsmen'] is List) {
      _batters = (r['batsmen'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (r['bowlers'] is List) {
      _bowlers = (r['bowlers'] as List).whereType<Map<String, dynamic>>().toList();
    }
    if (r['commentaries'] is List) {
      _commentary = (r['commentaries'] as List).whereType<Map<String, dynamic>>().toList();
    }

    if (r['live_inning'] is Map) {
      final inn = r['live_inning'] as Map;
      if (inn['equations'] is Map) {
        final eq = inn['equations'] as Map;
        _crr = (eq['runrate'] ?? '-').toString();
        _rrr = (eq['required_runrate'] ?? '-').toString();
        _target = (eq['target'] ?? '-').toString();
      }
      if (inn['current_partnership'] is Map) {
        final cp = inn['current_partnership'] as Map;
        _pship = '${cp['runs'] ?? 0}(${cp['balls'] ?? 0})';
      }
      if (inn['last_wicket'] is Map) {
        final lw = inn['last_wicket'] as Map;
        _lastWkt = '${lw['name'] ?? ''} ${lw['runs'] ?? 0}(${lw['balls'] ?? 0})';
      }
      final rs = (inn['recent_scores'] ?? '').toString().trim();
      if (rs.isNotEmpty) {
        _recentBalls = rs.split(RegExp(r'[,|\s]+')).where((s) => s.isNotEmpty).take(10).toList();
      }
    }

    if (r['live_odds'] is Map && r['live_odds']['matchodds'] is Map) {
      final mo = r['live_odds']['matchodds'] as Map;
      final ta = mo['teama'] is Map ? mo['teama'] as Map : null;
      final tb = mo['teamb'] is Map ? mo['teamb'] as Map : null;
      if (ta != null && (ta['back'] ?? '').toString().isNotEmpty) {
        _oddsTeam = _m.teamA;
        _oddsBack = (ta['back'] ?? '-').toString();
        _oddsLay = (ta['lay'] ?? '-').toString();
      } else if (tb != null && (tb['back'] ?? '').toString().isNotEmpty) {
        _oddsTeam = _m.teamB;
        _oddsBack = (tb['back'] ?? '-').toString();
        _oddsLay = (tb['lay'] ?? '-').toString();
      }
    }

    if (r['session_odds'] is List && (r['session_odds'] as List).isNotEmpty) {
      final first = (r['session_odds'] as List).first;
      if (first is Map) {
        _sessionTitle = (first['title'] ?? 'Session').toString();
        _sessionBack = (first['back'] ?? first['yes'] ?? '-').toString();
        _sessionLay = (first['lay'] ?? first['no'] ?? '-').toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          title: Text(_m.shortTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: _toggleAuto,
              child: Text(
                _autoLive ? 'Auto ON' : 'Auto 15s',
                style: TextStyle(
                  color: _autoLive ? const Color(0xFFD81B60) : const Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _loadLiveAndScorecard,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Live'),
              Tab(text: 'Commentary'),
              Tab(text: 'Scorecard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _InfoTile(title: 'Match', value: _m.title),
                _InfoTile(title: 'Series', value: _m.competition.isEmpty ? _m.subtitle : _m.competition),
                _InfoTile(title: 'Venue', value: _m.venue),
                _InfoTile(title: 'Date', value: _m.dateStartIst),
                _InfoTile(title: 'Toss', value: _toss),
              ],
            ),
            _buildLiveTab(),
            _buildCommentaryTab(),
            _buildScorecardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTab() {
    final topScore = _m.teamBScore != '-' ? '${_m.teamB} ${_m.teamBScore}' : '${_m.teamA} ${_m.teamAScore}';

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Container(
          height: 85,
          color: Colors.black,
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  _m.statusCode == 3 ? '• Live' : _m.statusStr,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  topScore,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('${_m.teamA}: ${_m.teamAScore}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text('${_m.teamB}: ${_m.teamBScore}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00897B)))),
                ],
              ),
              if (_m.statusNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_m.statusNote, style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ],
          ),
        ),
        if (_recentBalls.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Recent: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ..._recentBalls.map((b) => _BallCircle(label: b)),
                ],
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Text('CRR: $_crr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 20),
                Text('RRR: $_rrr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 20),
                Text('Target: $_target', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    const Text('Win Probability  ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text('${_oddsTeam.isEmpty ? _m.teamA : _oddsTeam}: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    _RateBox(text: _oddsBack, isPink: true),
                    const SizedBox(width: 4),
                    _RateBox(text: _oddsLay, isPink: false),
                  ],
                ),
              ),
              const Divider(height: 14, color: Color(0xFFEEEEEE)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  children: [
                    Text('$_sessionTitle: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    _RateBox(text: _sessionBack, isPink: true),
                    const SizedBox(width: 4),
                    _RateBox(text: _sessionLay, isPink: false),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_batters.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(flex: 5, child: Text('Batter', style: TextStyle(color: Colors.grey, fontSize: 11))),
                    Expanded(child: Text('R', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))),
                    Expanded(child: Text('B', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))),
                    Expanded(child: Text('4s', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))),
                    Expanded(child: Text('6s', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))),
                    Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 11))),
                  ],
                ),
                const Divider(),
                ..._batters.map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(flex: 5, child: Text((b['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Expanded(child: Text('${b['runs'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(child: Text('${b['balls_faced'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                          Expanded(child: Text('${b['fours'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                          Expanded(child: Text('${b['sixes'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text('${b['strike_rate'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    )),
                if (_pship != '-' || _lastWkt != '-') ...[
                  const Divider(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text("P'ship: $_pship", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 14),
                        Text("L' Wkt: $_lastWkt", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (_bowlers.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bowler', style: TextStyle(color: Colors.grey, fontSize: 11)),
                const Divider(),
                ..._bowlers.map((bw) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text((bw['name'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                          Text('${bw['overs'] ?? 0} O • ${bw['runs_conceded'] ?? 0} R • ${bw['wickets'] ?? 0} W • ECO ${bw['econ'] ?? 0}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCommentaryTab() {
    if (_commentary.isEmpty) {
      return const Center(child: Text('Commentary abhi available nahi hai.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _commentary.length,
      itemBuilder: (_, i) {
        final c = _commentary[i];
        final ov = c['over'] != null ? '${c['over']}.${c['ball'] ?? 0}: ' : '';
        final txt = (c['commentary'] ?? c['text'] ?? '').toString();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Text('$ov$txt', style: const TextStyle(fontSize: 13)),
        );
      },
    );
  }

  Widget _buildScorecardTab() {
    if (_scorecardInnings.isEmpty) {
      return const Center(child: Text('Scorecard abhi available nahi hai.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _scorecardInnings.length,
      itemBuilder: (_, idx) {
        final inn = _scorecardInnings[idx];
        final name = (inn['name'] ?? 'Innings ${idx + 1}').toString();
        final batsmen = (inn['batsmen'] is List) ? List.from(inn['batsmen']) : <dynamic>[];
        final bowlers = (inn['bowlers'] is List) ? List.from(inn['bowlers']) : <dynamic>[];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00897B))),
              const Divider(),
              ...batsmen.map((b) {
                final m = b is Map ? b : {};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text((m['name'] ?? '').toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Text('${m['runs'] ?? 0} (${m['balls_faced'] ?? 0}) • SR ${m['strike_rate'] ?? 0}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
              if (bowlers.isNotEmpty) ...[
                const Divider(),
                const Text('Bowling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD81B60))),
                ...bowlers.map((bw) {
                  final m = bw is Map ? bw : {};
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text((m['name'] ?? '').toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        Text('${m['overs'] ?? 0} O • ${m['runs_conceded'] ?? 0} R • ${m['wickets'] ?? 0} W', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _RateBox extends StatelessWidget {
  final String text;
  final bool isPink;
  const _RateBox({required this.text, required this.isPink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isPink ? const Color(0xFFFDE8EC) : const Color(0xFFE0F5F2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: isPink ? const Color(0xFFD81B60) : const Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _BallCircle extends StatelessWidget {
  final String label;
  const _BallCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFFEFEFEF);
    Color fg = Colors.black;
    if (label == '4') {
      bg = const Color(0xFF3E7CB1);
      fg = Colors.white;
    } else if (label == '6') {
      bg = const Color(0xFF6B4FA2);
      fg = Colors.white;
    } else if (label == '1' || label == '2' || label == '3') {
      bg = const Color(0xFF2E9F57);
      fg = Colors.white;
    } else if (label.toUpperCase() == 'W') {
      bg = Colors.redAccent;
      fg = Colors.white;
    }
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title, value;
  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class SeriesTab extends StatelessWidget {
  const SeriesTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Series & Points Table'));
}

class RankingsTab extends StatelessWidget {
  const RankingsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('ICC Rankings'));
}

class NewsTab extends StatelessWidget {
  const NewsTab({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Cricket News'));
}
