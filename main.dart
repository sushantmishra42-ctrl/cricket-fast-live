import 'dart:async';
import 'package:flutter/material.dart';

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

class Batter {
  String name;
  int runs;
  int balls;
  int fours;
  int sixes;
  bool isStriker;
  bool isOut;

  Batter({
    required this.name,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    this.isStriker = false,
    this.isOut = false,
  });

  String get sr =>
      balls == 0 ? '0.0' : ((runs / balls) * 100).toStringAsFixed(1);
}

class Bowler {
  String name;
  int overs;
  int ballsInOver;
  int runs;
  int wickets;

  Bowler({
    required this.name,
    required this.overs,
    required this.ballsInOver,
    required this.runs,
    required this.wickets,
  });

  String get oversText => '$overs.$ballsInOver';
  String get eco {
    final total = overs + (ballsInOver / 6.0);
    return total == 0 ? '0.00' : (runs / total).toStringAsFixed(2);
  }
}

class CricketMatch {
  final String id;
  final String series;
  final String matchTitle;
  final String team1;
  final String team2;
  final String team1Score;
  int runs;
  int wickets;
  int overs;
  int balls;
  final int target;
  final String venue;
  final String toss;
  int probLow;
  int probHigh;
  int sessionLow;
  int sessionHigh;
  int rxbRuns;
  int rxbBalls;
  int pshipRuns;
  int pshipBalls;
  String lastWicket;
  String lastEvent;
  int overRuns;
  final List<String> overBalls;
  final List<String> commentary;
  final List<String> overHistory;
  final List<Batter> batters;
  final List<Bowler> bowlers;
  final List<String> nextBatters;

  CricketMatch({
    required this.id,
    required this.series,
    required this.matchTitle,
    required this.team1,
    required this.team2,
    required this.team1Score,
    required this.runs,
    required this.wickets,
    required this.overs,
    required this.balls,
    required this.target,
    required this.venue,
    required this.toss,
    required this.probLow,
    required this.probHigh,
    required this.sessionLow,
    required this.sessionHigh,
    required this.rxbRuns,
    required this.rxbBalls,
    required this.pshipRuns,
    required this.pshipBalls,
    required this.lastWicket,
    required this.lastEvent,
    required this.overRuns,
    required this.overBalls,
    required this.commentary,
    required this.overHistory,
    required this.batters,
    required this.bowlers,
    required this.nextBatters,
  });

  String get scoreText => '$runs-$wickets';
  String get oversText => '$overs.$balls';
  int get ballsBowled => overs * 6 + balls;
  int get ballsRem => (120 - ballsBowled).clamp(0, 120);
  int get runsNeeded => (target - runs).clamp(0, 999);

  String get crr {
    if (ballsBowled == 0) return '0.00';
    return (runs / (ballsBowled / 6.0)).toStringAsFixed(2);
  }

  String get rrr {
    if (ballsRem == 0) return '0.00';
    return ((runsNeeded / ballsRem) * 6.0).toStringAsFixed(2);
  }

  String get statusText {
    if (runs >= target) return '$team2 won by ${10 - wickets} wickets';
    if (wickets >= 10 || ballsRem == 0)
      return '$team1 won by ${target - 1 - runs} runs';
    return '$team2 need $runsNeeded runs in $ballsRem balls';
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _navIndex = 0;

  late final List<CricketMatch> _liveMatches = [
    CricketMatch(
      id: 'm1',
      series: 'Australia Tour of England • 2nd T20I',
      matchTitle: 'AUS vs ENG',
      team1: 'ENG',
      team2: 'AUS',
      team1Score: '187-9 (20.0)',
      runs: 37,
      wickets: 1,
      overs: 3,
      balls: 5,
      target: 188,
      venue: 'Melbourne Cricket Ground (MCG)',
      toss: 'AUS won the toss and elected to bowl',
      probLow: 84,
      probHigh: 85,
      sessionLow: 59,
      sessionHigh: 60,
      rxbRuns: 23,
      rxbBalls: 13,
      pshipRuns: 34,
      pshipBalls: 17,
      lastWicket: 'J. Fraser-McGurk 1(3)',
      lastEvent: '4',
      overRuns: 21,
      overBalls: ['WD', '4', '2', '4', '6', '4'],
      commentary: [
        '3.5: Archer to Sam Harper, FOUR! Punched cleanly through cover.',
        '3.4: Archer to Sam Harper, SIX! Massive strike over deep square leg.',
        '3.3: Archer to Sam Harper, FOUR! Cracking straight drive.',
        '3.2: Archer to Mitchell Marsh, 2 runs, tucked off the pads.',
        '3.1: Archer to Mitchell Marsh, FOUR! Short and pulled away.',
      ],
      overHistory: [
        'Over 3 (7 Runs): 1  0  2  1  2  1',
        'Over 2 (5 Runs • 1 Wkt): 0  1  W  0  3  1',
        'Over 1 (4 Runs): 0  1  0  2  0  1',
      ],
      batters: [
        Batter(
            name: 'J. Fraser-McGurk',
            runs: 1,
            balls: 3,
            fours: 0,
            sixes: 0,
            isOut: true),
        Batter(
            name: 'Mitchell Marsh',
            runs: 12,
            balls: 10,
            fours: 0,
            sixes: 1,
            isStriker: false),
        Batter(
            name: 'Sam Harper',
            runs: 23,
            balls: 10,
            fours: 3,
            sixes: 1,
            isStriker: true),
      ],
      bowlers: [
        Bowler(
            name: 'Jofra Archer',
            overs: 1,
            ballsInOver: 5,
            runs: 25,
            wickets: 0),
        Bowler(
            name: 'Mark Wood', overs: 2, ballsInOver: 0, runs: 12, wickets: 1),
      ],
      nextBatters: [
        'Glenn Maxwell',
        'Marcus Stoinis',
        'Tim David',
        'Matthew Wade'
      ],
    ),
    CricketMatch(
      id: 'm2',
      series: 'Indian T20 League • Match 18',
      matchTitle: 'MI vs CSK',
      team1: 'CSK',
      team2: 'MI',
      team1Score: '198-5 (20.0)',
      runs: 156,
      wickets: 4,
      overs: 16,
      balls: 2,
      target: 199,
      venue: 'Wankhede Stadium, Mumbai',
      toss: 'MI won the toss and elected to bowl',
      probLow: 62,
      probHigh: 64,
      sessionLow: 192,
      sessionHigh: 195,
      rxbRuns: 43,
      rxbBalls: 22,
      pshipRuns: 51,
      pshipBalls: 28,
      lastWicket: 'S. Yadav 34(21)',
      lastEvent: '6',
      overRuns: 11,
      overBalls: ['1', '4', '0', '6'],
      commentary: [
        '16.2: Pathirana to Hardik, SIX! Launches it over long-on!',
        '16.1: Pathirana to Tilak, 1 run, clipped to mid-wicket.',
      ],
      overHistory: [
        'Over 16 (10 Runs): 1  4  1  0  2  2',
        'Over 15 (8 Runs • 1 Wkt): 4  W  1  1  1  1',
      ],
      batters: [
        Batter(
            name: 'Rohit Sharma',
            runs: 48,
            balls: 29,
            fours: 6,
            sixes: 2,
            isOut: true),
        Batter(
            name: 'S. Yadav',
            runs: 34,
            balls: 21,
            fours: 4,
            sixes: 1,
            isOut: true),
        Batter(
            name: 'Hardik Pandya',
            runs: 41,
            balls: 18,
            fours: 3,
            sixes: 3,
            isStriker: true),
        Batter(
            name: 'Tilak Varma',
            runs: 28,
            balls: 19,
            fours: 2,
            sixes: 1,
            isStriker: false),
      ],
      bowlers: [
        Bowler(
            name: 'M. Pathirana',
            overs: 2,
            ballsInOver: 2,
            runs: 24,
            wickets: 2),
        Bowler(
            name: 'R. Jadeja', overs: 4, ballsInOver: 0, runs: 29, wickets: 1),
      ],
      nextBatters: ['Naman Dhir', 'Mitchell Santner', 'Deepak Chahar'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeMatchesTab(
        liveMatches: _liveMatches,
        onRefresh: () => setState(() {}),
      ),
      const SeriesTab(),
      const RankingsTab(),
      const NewsTab(),
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
              child: const Icon(Icons.sports_cricket,
                  color: Color(0xFFFFD54F), size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Cricket Fast Live',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
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
                Text(
                  'LIVE',
                  style: TextStyle(
                      color: Color(0xFFD81B60),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Matches'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Series'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: 'Rankings'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
        ],
      ),
    );
  }
}

class HomeMatchesTab extends StatelessWidget {
  final List<CricketMatch> liveMatches;
  final VoidCallback onRefresh;

  const HomeMatchesTab({
    super.key,
    required this.liveMatches,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: 'LIVE'),
                Tab(text: 'UPCOMING'),
                Tab(text: 'FINISHED'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: liveMatches.length,
                  itemBuilder: (context, index) {
                    final m = liveMatches[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MatchDetailPage(match: m)),
                        );
                        onRefresh();
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
                                    m.series,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE8EC),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    '• Live',
                                    style: TextStyle(
                                        color: Color(0xFFD81B60),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.team1,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(m.team1Score,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(m.team2,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(
                                  '${m.scoreText} (${m.oversText})',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF00897B)),
                                ),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFEEEEEE)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    m.statusText,
                                    style: const TextStyle(
                                        color: Color(0xFFD81B60),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _RateBox(
                                        text: '${m.probLow}', isPink: true),
                                    const SizedBox(width: 4),
                                    _RateBox(
                                        text: '${m.probHigh}', isPink: false),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ListView(
                  padding: const EdgeInsets.all(10),
                  children: const [
                    _SimpleMatchTile(
                      series: 'Indian T20 League • Match 19',
                      teams: 'RCB vs KKR',
                      sub1: 'Today, 7:30 PM IST',
                      sub2: 'M. Chinnaswamy Stadium, Bengaluru',
                    ),
                    _SimpleMatchTile(
                      series: 'AUS Tour of ENG • 3rd T20I',
                      teams: 'ENG vs AUS',
                      sub1: 'Tomorrow, 7:00 PM IST',
                      sub2: 'Sydney Cricket Ground',
                    ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(10),
                  children: const [
                    _SimpleMatchTile(
                      series: 'AUS Tour of ENG • 1st T20I',
                      teams: 'AUS (194-4) vs ENG (180-8)',
                      sub1: 'AUS won by 14 runs',
                      sub2: 'Adelaide Oval • 2 days ago',
                    ),
                    _SimpleMatchTile(
                      series: 'Indian T20 League • Match 17',
                      teams: 'RR (188-4) vs GT (185-7)',
                      sub1: 'RR won by 6 wickets',
                      sub2: 'Sawai Mansingh Stadium, Jaipur',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchDetailPage extends StatefulWidget {
  final CricketMatch match;
  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  bool _isMuted = true;
  bool _autoLive = false;
  Timer? _timer;
  int _simIndex = 0;
  final List<String> _simEvents = ['1', '4', '0', '6', '2', 'WD', 'W', '4'];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleAuto() {
    setState(() {
      _autoLive = !_autoLive;
      if (_autoLive) {
        _timer = Timer.periodic(const Duration(seconds: 2), (_) => _nextBall());
      } else {
        _timer?.cancel();
      }
    });
  }

  void _nextBall() {
    final m = widget.match;
    if (m.runs >= m.target || m.wickets >= 10 || m.ballsRem <= 0) {
      _timer?.cancel();
      setState(() => _autoLive = false);
      return;
    }

    final ev = _simEvents[_simIndex % _simEvents.length];
    _simIndex++;

    setState(() {
      m.lastEvent = ev;
      final activeBatters = m.batters.where((b) => !b.isOut).toList();
      if (activeBatters.isEmpty) return;

      final striker = activeBatters.firstWhere((b) => b.isStriker,
          orElse: () => activeBatters.first);
      final nonStriker = activeBatters.length > 1
          ? activeBatters.firstWhere((b) => b != striker,
              orElse: () => activeBatters.last)
          : null;
      final activeBowler = m.bowlers.first;

      if (m.balls == 0 && m.overBalls.length >= 6) {
        m.overHistory.insert(0,
            'Over ${m.overs} (${m.overRuns} Runs): ${m.overBalls.join('  ')}');
        m.overBalls.clear();
        m.overRuns = 0;
      }

      if (ev == 'WD') {
        m.runs += 1;
        m.overRuns += 1;
        m.pshipRuns += 1;
        activeBowler.runs += 1;
        m.overBalls.add('WD');
        m.rxbRuns = (m.rxbRuns - 1).clamp(0, 99);
        m.commentary.insert(0,
            '${m.oversText}: ${activeBowler.name} to ${striker.name}, WIDE! 1 extra run.');
        return;
      }

      m.balls += 1;
      if (m.balls >= 6) {
        m.overs += 1;
        m.balls = 0;
      }

      activeBowler.ballsInOver += 1;
      if (activeBowler.ballsInOver >= 6) {
        activeBowler.overs += 1;
        activeBowler.ballsInOver = 0;
      }

      m.rxbBalls = (m.rxbBalls - 1).clamp(0, 36);
      m.pshipBalls += 1;
      striker.balls += 1;
      m.overBalls.add(ev);

      if (ev == 'W') {
        m.wickets += 1;
        activeBowler.wickets += 1;
        striker.isOut = true;
        striker.isStriker = false;
        m.lastWicket = '${striker.name} ${striker.runs}(${striker.balls})';
        m.pshipRuns = 0;
        m.pshipBalls = 0;
        m.probLow = (m.probLow + 4).clamp(5, 95);
        m.probHigh = m.probLow + 1;
        m.sessionLow = (m.sessionLow - 3).clamp(30, 95);
        m.sessionHigh = m.sessionLow + 1;
        m.commentary.insert(0,
            '${m.oversText}: ${activeBowler.name} to ${striker.name}, OUT! Caught in the deep!');

        if (m.wickets < 10) {
          final nextName = m.nextBatters.isNotEmpty
              ? m.nextBatters.removeAt(0)
              : 'Batter ${m.wickets + 2}';
          m.batters.add(Batter(
              name: nextName,
              runs: 0,
              balls: 0,
              fours: 0,
              sixes: 0,
              isStriker: true));
        }
      } else {
        final r = int.parse(ev);
        m.runs += r;
        m.overRuns += r;
        m.pshipRuns += r;
        striker.runs += r;
        activeBowler.runs += r;
        m.rxbRuns = (m.rxbRuns - r).clamp(0, 99);
        if (r == 4) striker.fours += 1;
        if (r == 6) striker.sixes += 1;

        if (r >= 4) {
          m.probLow = (m.probLow - 3).clamp(5, 95);
          m.probHigh = m.probLow + 1;
          m.sessionLow = (m.sessionLow + 2).clamp(30, 95);
          m.sessionHigh = m.sessionLow + 1;
        }
        m.commentary.insert(0,
            '${m.oversText}: ${activeBowler.name} to ${striker.name}, $r ${r == 1 ? 'run' : 'runs'}.');

        if (r % 2 == 1 && nonStriker != null) {
          striker.isStriker = false;
          nonStriker.isStriker = true;
        }
      }

      if (m.balls == 0 && nonStriker != null && ev != 'W') {
        striker.isStriker = !striker.isStriker;
        nonStriker.isStriker = !nonStriker.isStriker;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final activeBatters = m.batters.where((b) => !b.isOut).toList();

    return DefaultTabController(
      length: 5,
      initialIndex: 1,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 44,
          title: Text(m.matchTitle,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            TextButton(
              onPressed: _toggleAuto,
              child: Text(
                _autoLive ? 'Pause' : 'Auto Live',
                style: TextStyle(
                  color: _autoLive
                      ? const Color(0xFFD81B60)
                      : const Color(0xFF00897B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              onPressed: _nextBall,
              icon: const Icon(Icons.skip_next, color: Colors.black),
              tooltip: 'Next Ball',
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
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(m),
            ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                // Black Live Ball Box
                Container(
                  height: 85,
                  color: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: GestureDetector(
                          onTap: () => setState(() => _isMuted = !_isMuted),
                          child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: Colors.white,
                              size: 18),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.topRight,
                        child: Text('• Live',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                      Center(
                        child: Text(
                          m.lastEvent,
                          style: TextStyle(
                            color: m.lastEvent == 'W'
                                ? Colors.redAccent
                                : m.lastEvent == '6'
                                    ? const Color(0xFF00E676)
                                    : Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Score Bar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text('${m.team2} ${m.scoreText} (${m.oversText})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('P',
                              style: TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        const SizedBox(width: 18),
                        Text('${m.team1} ${m.team1Score}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),

                // Over Strip
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      children: [
                        Text('Over ${m.overs + 1}  ',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        ...m.overBalls.map((b) => _BallCircle(label: b)),
                        Text('  = ${m.overRuns}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                // Runs Needed / CRR / RRR / Target
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            Text('Runs Needed: ${m.runsNeeded}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 28),
                            Text('Balls Rem: ${m.ballsRem}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const Divider(height: 12, color: Color(0xFFEEEEEE)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            Text('CRR: ${m.crr}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Text('RRR: ${m.rrr}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Text('Target: ${m.target}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Win Probability + 6 Over Runs + R X B
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            const Text('Win Probability  ',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                            const Icon(Icons.info_outline,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 20),
                            Text('${m.team1}: ',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500)),
                            _RateBox(text: '${m.probLow}', isPink: true),
                            const SizedBox(width: 4),
                            _RateBox(text: '${m.probHigh}', isPink: false),
                          ],
                        ),
                      ),
                      const Divider(height: 12, color: Color(0xFFEEEEEE)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            const Text('6 Over Runs: ',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500)),
                            _RateBox(text: '${m.sessionLow}', isPink: true),
                            const SizedBox(width: 4),
                            _RateBox(text: '${m.sessionHigh}', isPink: false),
                            const SizedBox(width: 14),
                            const Text('R X B: ',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w500)),
                            _RateBox(text: '${m.rxbRuns}', isPink: true),
                            const SizedBox(width: 4),
                            _RateBox(text: '${m.rxbBalls}', isPink: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Batter Table + P'ship + Last Wicket
                Container(
                  margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Text('Batter',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                          Expanded(
                              child: Text('R',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                          Expanded(
                              child: Text('B',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                          Expanded(
                              child: Text('4s',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                          Expanded(
                              child: Text('6s',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                          Expanded(
                              flex: 2,
                              child: Text('SR',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11))),
                        ],
                      ),
                      const Divider(height: 10, color: Color(0xFFEEEEEE)),
                      ...activeBatters.map(
                        (b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        b.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (b.isStriker) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.sports_cricket,
                                          size: 13, color: Color(0xFFC58B2B)),
                                    ],
                                  ],
                                ),
                              ),
                              Expanded(
                                  child: Text('${b.runs}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12))),
                              Expanded(
                                  child: Text('${b.balls}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12))),
                              Expanded(
                                  child: Text('${b.fours}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12))),
                              Expanded(
                                  child: Text('${b.sixes}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12))),
                              Expanded(
                                  flex: 2,
                                  child: Text(b.sr,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11))),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 10, color: Color(0xFFEEEEEE)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            Text("P'ship: ${m.pshipRuns}(${m.pshipBalls})",
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            Text("L' Wkt: ${m.lastWicket}",
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Simulate Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: ElevatedButton.icon(
                    onPressed: _nextBall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Simulate Next Ball',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
            _buildCommentaryTab(m),
            _buildScorecardTab(m),
            _buildHistoryTab(m),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(CricketMatch m) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _SimpleTile(title: 'Series', value: m.series),
        _SimpleTile(title: 'Match', value: m.matchTitle),
        _SimpleTile(title: 'Venue', value: m.venue),
        _SimpleTile(title: 'Toss', value: m.toss),
        const _SimpleTile(
            title: 'Pitch Report',
            value: 'Good batting surface; pace bowlers get bounce early.'),
      ],
    );
  }

  Widget _buildCommentaryTab(CricketMatch m) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: m.commentary.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Text(m.commentary[i], style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Widget _buildScorecardTab(CricketMatch m) {
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.team2} Batting: ${m.scoreText} (${m.oversText})',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF00897B))),
              const Divider(),
              ...m.batters.map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${b.name}${b.isOut ? '' : '*'}',
                          style: TextStyle(
                              fontWeight: b.isOut
                                  ? FontWeight.normal
                                  : FontWeight.bold)),
                      Text('${b.runs} (${b.balls}) • SR ${b.sr}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${m.team1} Bowling',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFD81B60))),
              const Divider(),
              ...m.bowlers.map(
                (bw) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(bw.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                          '${bw.oversText} O • ${bw.runs} R • ${bw.wickets} W • ECO ${bw.eco}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(CricketMatch m) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: m.overHistory.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(8)),
        child: Text(m.overHistory[i],
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class SeriesTab extends StatelessWidget {
  const SeriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', 'RR', '6', '5', '1', '10', '+0.76'],
      ['2', 'KKR', '5', '4', '1', '8', '+1.68'],
      ['3', 'MI', '6', '4', '2', '8', '+0.42'],
      ['4', 'CSK', '6', '3', '3', '6', '+0.15'],
      ['5', 'RCB', '6', '2', '4', '4', '-0.48'],
    ];

    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const Text('Indian T20 League — Points Table',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                      child: Text('#',
                          style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(
                      flex: 3,
                      child: Text('Team',
                          style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(
                      child: Text('M',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(
                      child: Text('W',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(
                      child: Text('Pts',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(
                      flex: 2,
                      child: Text('NRR',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey, fontSize: 12))),
                ],
              ),
              const Divider(),
              ...rows.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(r[0],
                              style: const TextStyle(color: Colors.grey))),
                      Expanded(
                          flex: 3,
                          child: Text(r[1],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                      Expanded(child: Text(r[2], textAlign: TextAlign.right)),
                      Expanded(child: Text(r[3], textAlign: TextAlign.right)),
                      Expanded(
                          child: Text(r[5],
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  color: Color(0xFF00897B),
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text(r[6],
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
            ],
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
    final teams = [
      ('1', 'India', '268'),
      ('2', 'Australia', '257'),
      ('3', 'England', '252'),
      ('4', 'South Africa', '248'),
      ('5', 'New Zealand', '244'),
    ];
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        const Text('ICC T20I Team Rankings',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...teams.map(
          (t) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${t.$1}  ${t.$2}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Rating: ${t.$3}',
                    style: const TextStyle(
                        color: Color(0xFF00897B), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NewsTab extends StatelessWidget {
  const NewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final stories = [
      (
        'AUS vs ENG 2nd T20I: Sam Harper powers chase at MCG',
        '10 mins ago • Match Report'
      ),
      (
        'MI vs CSK thriller goes into final overs at Wankhede',
        '1 hour ago • IPL Desk'
      ),
      (
        'ICC T20I Rankings: Top batters & bowlers updated',
        '4 hours ago • Stats Update'
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(10),
      children: stories
          .map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$1,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(s.$2,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          )
          .toList(),
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
    } else if (label == '2' || label == '1') {
      bg = const Color(0xFF2E9F57);
      fg = Colors.white;
    } else if (label == 'W') {
      bg = Colors.redAccent;
      fg = Colors.white;
    }
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(label,
          style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: label == 'WD' ? 8 : 10)),
    );
  }
}

class _SimpleMatchTile extends StatelessWidget {
  final String series, teams, sub1, sub2;
  const _SimpleMatchTile(
      {required this.series,
      required this.teams,
      required this.sub1,
      required this.sub2});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(series,
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 6),
          Text(teams,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(sub1,
              style: const TextStyle(
                  color: Color(0xFF00897B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          Text(sub2, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final String title, value;
  const _SimpleTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
