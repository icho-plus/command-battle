import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';// KeyEvent を扱うために必要
import 'package:audioplayers/audioplayers.dart'; // BGM, 効果音
import 'package:shared_preferences/shared_preferences.dart';// 設定を保存

final player = AudioPlayer(); // BGM
const double sizedBox20 = 20;
const double fontSize20 = 20;
const double fontSize36 = 36;

void main() {
  runApp(const MyApp());

  player.setReleaseMode(ReleaseMode.loop);
  player.play(AssetSource('sounds/my_favorite_getaway.mp3'));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToMkdirApp(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MkdirApp()),
    );
  }
  void _navigateToRankingScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()),
    );
  }
  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
            _navigateToMkdirApp(context);
          }
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
            _navigateToRankingScreen(context);
          }
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyS) {
            _navigateToSettingsScreen(context);
          }
        },
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'COMMAND BATTLE',
                style: TextStyle(
                  fontSize: fontSize36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: fontSize36),
              Text(
                '始める[e]\nランキング[r]\n設定[s]',
                style: TextStyle(
                  fontSize: fontSize20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final double _maxVolume = 1.0;
  final double _minVolume = 0.0;
  final double _volumeStep = 0.1;
  double _volume = 1.0;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _focusNode = FocusNode();

    // 画面表示後にキーボード入力を受け付ける
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // SharedPreferencesから音量を読み込む
  Future<void> _loadVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('bgm_volume') ?? _maxVolume;
    });
  }

  // 音量を変更し、AudioPlayerとSharedPreferencesに反映
  void _changeVolume(double value) async {
    if (value < _minVolume) value = _minVolume;
    if (value > _maxVolume) value = _maxVolume;

    setState(() {
      _volume = value;
    });

    // AudioPlayerの音量変更
    player.setVolume(value);

    // SharedPreferencesに音量を保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgm_volume', value);
  }

  // 戻る処理
  void _goBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定([s]でもどる)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          // 「sキー」で戻る
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyS) {
            _goBack();
          }

          // 「→キー」で音量UP (+0.1)
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.keyD || event.logicalKey == LogicalKeyboardKey.arrowRight)) {
            _changeVolume(_volume + _volumeStep);
          }

          // 「←キー」で音量DOWN (-0.1)
          if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.keyA || event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
            _changeVolume(_volume - _volumeStep);
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('BGM音量'),
              Slider(
                value: _volume,
                min: _minVolume,
                max: _maxVolume,
                divisions: 10,
                label: '${(_volume * 100).round()}%',
                onChanged: _changeVolume,
              ),
              const SizedBox(height: sizedBox20),
              const Text('音量変更：a[←] / d[→]'),
            ],
          ),
        ),
      ),
    );
  }
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, String>> scores = [];
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); // 画面表示後にフォーカスをセット
    });
    _loadScores();
  }

  @override
  void dispose() {
    _focusNode.dispose(); // メモリリーク防止
    super.dispose();
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? scoreEntries = prefs.getStringList('scores');

    if (scoreEntries != null) {
      setState(() {
        scores = scoreEntries.map((entry) {
          List<String> parts = entry.split(',');
          return {'score': parts[0], 'date': parts[1]}; // スコアと日付を分離
        }).toList()
          ..sort((b, a) => int.parse(a['score']!).compareTo(int.parse(b['score']!))); // スコア降順ソート
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキグン([r]でもどる)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyR) {
            Navigator.pop(context); // Rキーで戻る
          }
        },
        child: Center(
          child: scores.isEmpty
              ? const Text(
            'no scores',
            style: TextStyle(fontSize: fontSize20, color: Colors.white),
          )
              : ListView.builder(
            itemCount: scores.length > 5 ? 5 : scores.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Text(
                  '${index + 1}位',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                title: Text(
                  '${scores[index]['score']} 点',
                  style: const TextStyle(fontSize: fontSize20, color: Colors.white),
                ),
                subtitle: Text(
                  scores[index]['date']!,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MkdirApp extends StatefulWidget {
  const MkdirApp({super.key});

  @override
  _MkdirAppState createState() => _MkdirAppState();
}

class _MkdirAppState extends State<MkdirApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode(); // キーボードイベント用
  final List<String> _history = [];
  final ScrollController _scrollController = ScrollController();
  final int _totalSquares = 21; // 四角形の総数
  final int _crossAxisCount = 7; // 1行に表示する四角形の数
  final double _crossAxisSpacing = 4; // 列間の間隔
  final double _mainAxisSpacing = 4; // 行間の間隔
  final double _historyHeight = 140; // 履歴欄の高さ
  final Map<int, String?> _stagedItems = {}; // 状態変更を一時的に保持
  final int _alphaOffset = 97;

  int playerPosition = 0;
  int enemyPosition = 0;
  int score = 0;
  bool isGameOver = false;
  bool isPlayerTurn = true;
  String gameResult = '';
  Map<int, String?> _items = {};

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus(); // キーボードのフォーカスを設定
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyboardFocusNode.dispose(); // キーボードフォーカスを破棄
    super.dispose();
  }

  void _initializeGame() {
    setState(() {
      isGameOver = false;
      isPlayerTurn = true;
      gameResult = '';
      _items.clear();
      _stagedItems.clear();
      _history.clear();
      score = 0;

      // 初期の四角形を作成
      List<String> alphabet = List.generate(_totalSquares, (index) => String.fromCharCode(index+_alphaOffset));
      for (int i = 0; i < alphabet.length; i++) {
        _stagedItems[i] = alphabet[i];
      }
      _items = Map.from(_stagedItems);

      // プレイヤーと敵の初期位置を設定
      playerPosition = 0; // プレイヤーは左上

      Random random = Random();
      do {
        enemyPosition = random.nextInt(_totalSquares); // 敵はランダム位置
      } while (enemyPosition == playerPosition); // プレイヤーの位置と被らないように
    });
  }

  void _addToHistory(String message) {
    setState(() {
      _history.add(message);
      if (_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }
    });
  }

  void _changeScore(int change){
    score += change;
  }

  final int _defeatScore= -10000;

  void _handlePlayerCommand(String input) {
    const int mkdirScore = 500;
    const int rmScore = 500;
    const int cdScore = 100;
    const int errorScore = -1000;
    const int winScore = 10000;

    if (isGameOver || !isPlayerTurn) return;

    final mkdirRegex = RegExp(r'^mkdir\s+(.+)$');
    final rmRegex = RegExp(r'^rm\s+(.+)$');
    final cdRegex = RegExp(r'^cd\s+(.+)$');
    final lsRegex = RegExp(r'^ls$');
    final exitRegex = RegExp(r'^exit$');

    if (mkdirRegex.hasMatch(input)) {
      String dirName = mkdirRegex.firstMatch(input)!.group(1)!;
      bool isSpace = false;
      if (_stagedItems.values.contains(dirName)) {
        _changeScore(errorScore);
        _addToHistory('エラー: "$dirName" は既に存在しています。');
      } else {
        _changeScore(mkdirScore);
        setState(() {
          for (int i = 0; i < _totalSquares; i++) {
            if (_stagedItems[i] == null) {
              _stagedItems[i] = dirName;
              break;
            }
            if(i==_totalSquares-1){
              isSpace = true;
            }
          }
        });
        if(isSpace){
          _changeScore(errorScore);
          _addToHistory('エラー: "$dirName"を配置するスペースが存在しません。');
        }else{
          _addToHistory('プレイヤー: mkdir $dirName');
        }
      }
    } else if (rmRegex.hasMatch(input)) {
      String dirName = rmRegex.firstMatch(input)!.group(1)!;
      if (_stagedItems.values.contains(dirName)) {
        _changeScore(rmScore);
        setState(() {
          int targetIndex = _stagedItems.keys.firstWhere((index) => _stagedItems[index] == dirName);
          if (targetIndex == playerPosition) {
            _changeScore(_defeatScore);
            _endGame('Defeat...');
          } else if (targetIndex == enemyPosition) {
            _changeScore(winScore);
            _endGame('Win!');
          } else {
            _stagedItems[targetIndex] = null;
          }
        });
        _addToHistory('プレイヤー: rm $dirName');
      } else {
        _changeScore(errorScore);
        _addToHistory('エラー: "$dirName" は存在しません。');
      }
    } else if (cdRegex.hasMatch(input)) {
      String dirName = cdRegex.firstMatch(input)!.group(1)!;
      if (_stagedItems.values.contains(dirName)) {
        for (int i = 0; i < _totalSquares; i++) {
          if (_stagedItems[i] == null) {
            _changeScore(cdScore);
          }
        }
        //_changeScore(cdScore);
        setState(() {
          playerPosition = _stagedItems.keys.firstWhere((index) => _stagedItems[index] == dirName);
        });
        _addToHistory('プレイヤー: cd $dirName');
      } else {
        _changeScore(errorScore);
        _addToHistory('エラー: "$dirName" は存在しません。');
      }
    }else if(lsRegex.hasMatch(input)){
      setState(() {
        _items = Map.from(_stagedItems);
      });
      _addToHistory('プレイヤー: ls');
    }else if(exitRegex.hasMatch(input)){
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TitleScreen()), // タイトル画面に戻る
      );
    }else{
      _changeScore(errorScore);
      _addToHistory('エラー: コマンドは以下の形式で入力してください:\n1. mkdir [名前]\n2. rm [名前]\n3. cd [名前]\n4. ls\n5. exit');
    }

    _controller.clear();
    _focusNode.requestFocus();

    // プレイヤーのターンが終了したら敵のターンを開始
    setState(() {
      isPlayerTurn = false;
    });
    Future.delayed(const Duration(seconds: 1), _handleEnemyTurn);
  }


  void _handleEnemyTurn() {
    if (isGameOver) return;

    Random random = Random();
    List<int> availableIndexes = _stagedItems.keys.where((index) => _stagedItems[index] == null).toList();
    List<int> removableIndexes = _stagedItems.keys
        .where((index) => index != enemyPosition && _stagedItems[index] != null)
        .toList();
    List<int> movableIndexes = _stagedItems.keys
        .where((index) => index != playerPosition && _stagedItems[index] != null)
        .toList();

    String? command;
    int actionType = random.nextInt(3); // 0: mkdir, 1: rm, 2: cd

    switch (actionType) {
      case 0: // mkdir
        if (availableIndexes.isNotEmpty) {
          int targetIndex = availableIndexes[random.nextInt(availableIndexes.length)];
          String dirName = String.fromCharCode(targetIndex+_alphaOffset);
          setState(() {
            _stagedItems[targetIndex] = dirName;
            command = 'mkdir $dirName';
          });
        }
        break;

      case 1: // rm
        if (removableIndexes.isNotEmpty) {
          int targetIndex = removableIndexes[random.nextInt(removableIndexes.length)];
          String? dirName = _stagedItems[targetIndex];
          setState(() {
            if (targetIndex == playerPosition) {
              _changeScore(_defeatScore);
              _endGame('Defeat...');
            } else if (targetIndex == enemyPosition) {
              // 敵が自身の位置を削除しない
            } else {
              _stagedItems[targetIndex] = null;
              command = 'rm $dirName';
            }
          });
        }
        break;

      case 2: // cd
        if (movableIndexes.isNotEmpty) {
          int targetIndex = movableIndexes[random.nextInt(movableIndexes.length)];
          setState(() {
            enemyPosition = targetIndex;
            command = 'cd';
            // command = 'cd ${_stagedItems[targetIndex]}'; //デバッグ用
          });
        }
        break;
    }

    if (command != null) {
      _addToHistory('敵: $command');
    }

    // プレイヤーのターンに移行
    setState(() {
      isPlayerTurn = true;
    });
  }

  void _endGame(String result) {
    // Future<void> resetScores() async {
    //   final prefs = await SharedPreferences.getInstance();
    //   await prefs.remove('scores');
    // }
    Future<void> saveScore(int newScore) async {
      final prefs = await SharedPreferences.getInstance();
      List<String> scoreEntries = prefs.getStringList('scores') ?? [];

      String now = DateTime.now().toLocal().toString().split(' ')[0]; // "YYYY-MM-DD" 形式に変換
      scoreEntries.add('$newScore,$now'); // スコアと日付を「,」で結合

      await prefs.setStringList('scores', scoreEntries);
    }

    setState(() {
      //resetScores();
      saveScore(score);
      isGameOver = true;
      gameResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game Over'),
          backgroundColor: Colors.black, // AppBar背景色を黒に
        ),
          body: KeyboardListener(
            focusNode: _keyboardFocusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.keyT) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TitleScreen()),
                  );
                } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MkdirApp()),
                  );
                }
              }
            },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gameResult,
                style: const TextStyle(fontSize: fontSize36, fontWeight: FontWeight.bold, color: Colors.white), // 白色
              ),
              Text(
                "Score:$score点",
                style: const TextStyle(fontSize: fontSize36, fontWeight: FontWeight.bold, color: Colors.white), // 白色
              ),
              const SizedBox(height: fontSize20),
              const Text(
                'リトライ[r]\nタイトル[t]',
                style: TextStyle(
                  fontSize: fontSize20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('COMMAND BATTLE'),
        backgroundColor: Colors.black, // AppBarの背景色を黒に設定
        foregroundColor: Colors.white, // 戻るボタンやアイコンの色を白に設定
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Score: $score',
                style: const TextStyle(fontSize: fontSize20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _crossAxisCount, // 四角形を縮小するために列の数を増やす
                crossAxisSpacing: _crossAxisSpacing, // 列間の間隔
                mainAxisSpacing: _mainAxisSpacing, // 行間の間隔
              ),
              itemCount: _totalSquares,
              itemBuilder: (context, index) {
                Color squareColor = Colors.grey[300]!;
                if (index == playerPosition) {
                  squareColor = Colors.blue;
                } else if (index == enemyPosition) {
                  // squareColor = Colors.red;
                  squareColor = Colors.yellow;
                } else if (_items[index] != null) {
                  squareColor = Colors.yellow;
                }

                return Container(
                  margin: const EdgeInsets.all(2),
                  color: squareColor,
                  child: Center(
                    child: Text(
                      _items[index] ?? '',
                      style: const TextStyle(
                          fontSize: fontSize20,
                          color: Colors.black, //四角形のテキストの色
                      ),

                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: _historyHeight,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return Text(_history[index]);
              },
            ),
          ),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: const TextStyle(
              color: Colors.green, // 入力文字の色
            ),
            decoration: const InputDecoration(
              hintText: 'mkdir:作成, rm:削除, cd:移動, ls:表示, exit:中断',
              hintStyle: TextStyle(color: Colors.green), // プレースホルダーの色
            ),
            onSubmitted: _handlePlayerCommand,
          ),
        ],
      ),
    );
  }
}