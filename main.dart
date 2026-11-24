import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
const String kCricketApiKey = '4cd3a388-7b5f-4ef4-ba14-76ccdcbbda7b';
void main() {
  runApp(const CricketGuruApp());
}

class CricketGuruApp extends StatelessWidget {
  const CricketGuruApp({super.key});

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

class ApiMatch {
  final String id;
  final String name;
  final String matchType;
  final String status;
  final String venue;
  final String date;
  final String team1;
  final String team2;
  final String score1;
  final String score2;
  final bool matchStarted;
  final bool matchEnded;
  final bool isDemo;

  ApiMatch({
    required this.id,
    required this.name,
    required this.matchType,
    required this.status,
    required this.venue,
    required this.date,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
    required this.matchStarted,
    required this.matchEnded,
    this.isDemo = false,
  });

  factory ApiMatch.fromJson(Map<String, dynamic> j) {
    final teams = (j['teams'] is List) ? List.from(j['teams']) : <dynamic>[];
    final teamInfo = (j['teamInfo'] is List) ? List.from(j['teamInfo']) : <dynamic>[];

    String shortName(int idx, String fallback) {
      if (idx < teamInfo.length && teamInfo[idx] is Map) {
        final m = teamInfo[idx] as Map;
        final sn = (m['shortname'] ?? '').toString().trim();
        if (sn.isNotEmpty) return sn;
        final nm = (m['name'] ?? '').toString().trim();
        if (nm.isNotEmpty) return nm;
      }
      if (idx < teams.length) return teams[idx].toString();
      return fallback;
    }

    final t1 = shortName(0, 'Team 1');
    final t2 = shortName(1, 'Team 2');

    String s1 = '-';
    String s2 = '-';
    if (j['score'] is List) {
      final scores = List.from(j['score']);
      if (scores.isNotEmpty && scores[0] is Map) {
        final sc = scores[0] as Map;
        s1 = '${sc['r'] ?? 0}-${sc['w'] ?? 0} (${sc['o'] ?? 0})';
      }
      if (scores.length > 1 && scores[1] is Map) {
        final sc = scores[1] as Map;
        s2 = '${sc['r'] ?? 0}-${sc['w'] ?? 0} (${sc['o'] ?? 0})';
      }
    }

    return ApiMatch(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? '$t1 vs $t2').toString(),
      matchType: (j['matchType'] ?? 'T20').toString().toUpperCase(),
      status: (j['status'] ?? '').toString(),
      venue: (j['venue'] ?? 'TBA').toString(),
      date: (j['date'] ?? '').toString(),
      team1: t1,
      team2: t2,
      score1: s1,
      score2: s2,
      matchStarted: j['matchStarted'] == true,
      matchEnded: j['matchEnded'] == true,
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
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
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
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8EC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFFD81B60), size: 8),
                SizedBox(width: 5),
                Text('LIVE API', style: TextStyle(color: Color(0xFFD81B60), fontSize: 11, fontWeight: FontWeight.bold)),
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
  List<ApiMatch> _matches = [];

  final ApiMatch _demoFallback = ApiMatch(
    id: 'demo',
    name: 'AUS vs ENG • 2nd T20I (Demo)',
    matchType: 'T20',
    status: 'AUS need 151 runs in 97 balls',
    venue: 'Melbourne Cricket Ground',
    date: 'Live Demo',
    team1: 'ENG',
    team2: 'AUS',
    score1: '187-9 (20.0)',
    score2: '37-1 (3.5)',
    matchStarted: true,
    matchEnded: false,
    isDemo: true,
  );

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    if (kCricketApiKey == 'YOUR_API_KEY_HERE' || kCricketApiKey.trim().isEmpty) {
      setState(() {
        _bannerMsg = 'API Key daalna baaki hai — abhi Demo match dikh raha hai.';
        _matches = [_demoFallback];
      });
      return;
    }

    setState(() {
      _loading = true;
      _bannerMsg = null;
    });

    try {
      final url = Uri.parse(
        'https://api.cricapi.com/v1/currentMatches?apikey=${kCricketApiKey.trim()}&offset=0',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          _bannerMsg = 'Server error (${res.statusCode}). Demo mode chalu hai.';
          if (_matches.isEmpty) _matches = [_demoFallback];
        });
        return;
      }

      final body = jsonDecode(res.body);
      if (body is Map && body['status'] == 'success' && body['data'] is List) {
        final list = (body['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => ApiMatch.fromJson(e))
            .toList();
        setState(() {
          _loading = false;
          _matches = list.isEmpty ? [_demoFallback] : list;
          _bannerMsg = list.isEmpty ? 'Abhi koi match nahi mila.' : null;
        });
      } else {
        final reason = (body is Map && body['reason'] != null)
            ? body['reason'].toString()
            : 'API limit ya invalid key.';
        setState(() {
          _loading = false;
          _bannerMsg = reason;
          if (_matches.isEmpty) _matches = [_demoFallback];
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _bannerMsg = 'Internet check karein (Refresh dabayein).';
        if (_matches.isEmpty) _matches = [_demoFallback];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = _matches.where((m) => m.matchStarted && !m.matchEnded).toList();
    final upcoming = _matches.where((m) => !m.matchStarted).toList();
    final finished = _matches.where((m) => m.matchEnded).toList();

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
                  onPressed: _loading ? null : _fetchMatches,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh Live Score',
                ),
              ],
            ),
          ),
          if (_bannerMsg != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8E1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                _bannerMsg!,
                style: const TextStyle(fontSize: 11, color: Color(0xFF8D6E00), fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(live, 'Abhi koi Live match nahi chal raha.'),
                _buildList(upcoming, 'Koi Upcoming match nahi mila.'),
                _buildList(finished, 'Koi Finished match nahi mila.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ApiMatch> list, String emptyText) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchMatches,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(emptyText, style: const TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final m = list[i];
          final isLive = m.matchStarted && !m.matchEnded;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ApiMatchDetailPage(match: m)),
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
                          '${m.matchType} • ${m.name}',
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
                          isLive ? '• Live' : (m.matchEnded ? 'Result' : 'Upcoming'),
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
                      Expanded(child: Text(m.team1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      Text(m.score1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(m.team2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      Text(m.score2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                    ],
                  ),
                  const Divider(height: 16, color: Color(0xFFEEEEEE)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          m.status.isEmpty ? m.venue : m.status,
                          style: const TextStyle(color: Color(0xFFD81B60), fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text('Scorecard ›', style: TextStyle(color: Color(0xFF00897B), fontSize: 12, fontWeight: FontWeight.bold)),
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

class ApiMatchDetailPage extends StatefulWidget {
  final ApiMatch match;
  const ApiMatchDetailPage({super.key, required this.match});

  @override
  State<ApiMatchDetailPage> createState() => _ApiMatchDetailPageState();
}

class _ApiMatchDetailPageState extends State<ApiMatchDetailPage> {
  bool _loading = false;
  bool _autoRefresh = false;
  Timer? _timer;
  List<dynamic> _inningsScorecards = [];
  String _toss = 'Info available on live match';
  late ApiMatch _m;

  @override
  void initState() {
    super.initState();
    _m = widget.match;
    if (!_m.isDemo && kCricketApiKey != 'YOUR_API_KEY_HERE') {
      _loadScorecard();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleAuto() {
    setState(() {
      _autoRefresh = !_autoRefresh;
      if (_autoRefresh) {
        _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadScorecard());
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _loadScorecard() async {
    if (_m.isDemo || kCricketApiKey == 'YOUR_API_KEY_HERE') return;
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
        'https://api.cricapi.com/v1/match_scorecard?apikey=${kCricketApiKey.trim()}&id=${_m.id}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['status'] == 'success' && body['data'] is Map) {
          final d = body['data'] as Map<String, dynamic>;
          setState(() {
            _m = ApiMatch.fromJson(d);
            if (d['tossWinner'] != null) {
              _toss = '${d['tossWinner']} won toss (${d['tossChoice'] ?? ''})';
            }
            if (d['scorecard'] is List) {
              _inningsScorecards = List.from(d['scorecard']);
            }
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 46,
          title: Text('${_m.team1} vs ${_m.team2}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: _toggleAuto,
              child: Text(
                _autoRefresh ? 'Auto ON' : 'Auto 30s',
                style: TextStyle(
                  color: _autoRefresh ? const Color(0xFFD81B60) : const Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              onPressed: _loading ? null : _loadScorecard,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Live'),
              Tab(text: 'Scorecard'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(10),
              children: [
                _InfoTile(title: 'Match', value: _m.name),
                _InfoTile(title: 'Format', value: _m.matchType),
                _InfoTile(title: 'Venue', value: _m.venue),
                _InfoTile(title: 'Date', value: _m.date),
                _InfoTile(title: 'Toss', value: _toss),
              ],
            ),
            _buildLiveTab(),
            _buildScorecardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTab() {
    List<dynamic> latestBatting = [];
    if (_inningsScorecards.isNotEmpty && _inningsScorecards.last is Map) {
      final lastInn = _inningsScorecards.last as Map;
      if (lastInn['batting'] is List) {
        latestBatting = List.from(lastInn['batting']);
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Container(
          height: 90,
          color: Colors.black,
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  _m.matchEnded ? '• Result' : '• Live',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  _m.score2 != '-' ? _m.score2 : _m.score1,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_m.team1}: ${_m.score1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${_m.team2}: ${_m.score2}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00897B))),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_m.status, style: const TextStyle(color: Color(0xFFD81B60), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Match Insights (Sample)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Row(
                    children: [
                      _RateBox(text: '84', isPink: true),
                      SizedBox(width: 4),
                      _RateBox(text: '85', isPink: false),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text('Note: Live odds/session ke liye paid Live Line API lagti hai.', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
        if (latestBatting.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                ...latestBatting.take(4).map((b) {
                  final bm = b is Map ? b : {};
                  final name = (bm['batsman'] is Map) ? (bm['batsman']['name'] ?? '').toString() : 'Batter';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(flex: 5, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        Expanded(child: Text('${bm['r'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(child: Text('${bm['b'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        Expanded(child: Text('${bm['4s'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        Expanded(child: Text('${bm['6s'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                        Expanded(flex: 2, child: Text('${bm['sr'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildScorecardTab() {
    if (_inningsScorecards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Scorecard data abhi available nahi hai (ya match start nahi hua).', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _inningsScorecards.length,
      itemBuilder: (_, idx) {
        final inn = _inningsScorecards[idx] is Map ? _inningsScorecards[idx] as Map : {};
        final title = (inn['inning'] ?? 'Innings ${idx + 1}').toString();
        final batting = (inn['batting'] is List) ? List.from(inn['batting']) : <dynamic>[];
        final bowling = (inn['bowling'] is List) ? List.from(inn['bowling']) : <dynamic>[];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00897B))),
              const Divider(),
              ...batting.map((b) {
                final bm = b is Map ? b : {};
                final name = (bm['batsman'] is Map) ? (bm['batsman']['name'] ?? '').toString() : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      Text('${bm['r'] ?? 0} (${bm['b'] ?? 0})  SR ${bm['sr'] ?? 0}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),
              if (bowling.isNotEmpty) ...[
                const Divider(),
                const Text('Bowling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD81B60))),
                const SizedBox(height: 4),
                ...bowling.map((bw) {
                  final m = bw is Map ? bw : {};
                  final name = (m['bowler'] is Map) ? (m['bowler']['name'] ?? '').toString() : '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        Text('${m['o'] ?? 0} O • ${m['r'] ?? 0} R • ${m['w'] ?? 0} W', style: const TextStyle(fontSize: 12)),
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
        style: TextStyle(
          color: isPink ? const Color(0xFFD81B60) : const Color(0xFF00897B),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
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
  Widget build(BuildContext context) {
    final rows = [
      ['1', 'RR', '6', '5', '10', '+0.76'],
      ['2', 'KKR', '5', '4', '8', '+1.68'],
      ['3', 'MI', '6', '4', '8', '+0.42'],
      ['4', 'CSK', '6', '3', '6', '+0.15'],
    ];
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const Text('Points Table', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: rows
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(r[0])),
                          Expanded(flex: 3, child: Text(r[1], style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text(r[2], textAlign: TextAlign.right)),
                          Expanded(child: Text(r[4], textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(r[5], textAlign: TextAlign.right)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class RankingsTab extends StatelessWidget {
  const RankingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final teams = [('1', 'India', '268'), ('2', 'Australia', '257'), ('3', 'England', '252')];
    return ListView(
      padding: const EdgeInsets.all(10),
      children: teams
          .map((t) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${t.$1} ${t.$2}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rating: ${t.$3}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class NewsTab extends StatelessWidget {
  const NewsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: const [
        _InfoTile(title: 'Live API Connected', value: 'Pull down or tap Refresh to fetch real-time international & league scores.'),
      ],
    );
  }
}
