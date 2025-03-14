import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';// KeyEvent を扱うために必要
import 'package:audioplayers/audioplayers.dart'; //BGM, 効果音
import 'package:shared_preferences/shared_preferences.dart';

final player = AudioPlayer();

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
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyS) {
            _navigateToSettingsScreen(context);
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'COMMAND BATTLE',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _navigateToMkdirApp(context),
                child: const Text(
                  '始める[e]',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _navigateToSettingsScreen(context),
                child: const Text(
                  '設定[s]',
                  style: TextStyle(fontSize: 20),
                ),
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
      _volume = prefs.getDouble('bgm_volume') ?? 1.0;
    });
  }

  // 音量を変更し、AudioPlayerとSharedPreferencesに反映
  void _changeVolume(double value) async {
    if (value < 0.0) value = 0.0;
    if (value > 1.0) value = 1.0;

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
        backgroundColor: Colors.black,
        title: const Text('設定画面'),
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
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _changeVolume(_volume + 0.1);
          }

          // 「←キー」で音量DOWN (-0.1)
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _changeVolume(_volume - 0.1);
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('BGM音量'),
              Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(_volume * 100).round()}%',
                onChanged: _changeVolume,
              ),
              ElevatedButton(
                onPressed: _goBack,
                child: const Text('戻る [s]'),
              ),
              const SizedBox(height: 20),
              const Text('音量変更：← / →'),
            ],
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
  final int totalSquares = 21; // 四角形の総数
  final int crossAxisCount = 7; // 1行に表示する四角形の数
  final double crossAxisSpacing = 4; // 列間の間隔
  final double mainAxisSpacing = 4; // 行間の間隔
  final double historyHeight = 140; // 履歴欄の高さ
  final Map<int, String?> _stagedItems = {}; // 状態変更を一時的に保持

  int playerPosition = 0;
  int enemyPosition = 0;
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

      // 初期の四角形を作成
      List<String> alphabet = List.generate(totalSquares, (index) => String.fromCharCode(97 + index));
      for (int i = 0; i < alphabet.length; i++) {
        _stagedItems[i] = alphabet[i];
      }
      _items = Map.from(_stagedItems);

      // プレイヤーと敵の初期位置を設定
      playerPosition = 0; // プレイヤーは左上

      Random random = Random();
      do {
        enemyPosition = random.nextInt(totalSquares); // 敵はランダム位置
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

  void _handlePlayerCommand(String input) {
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
        _addToHistory('エラー: "$dirName" は既に存在しています。');
      } else {
        setState(() {
          for (int i = 0; i < totalSquares; i++) {
            if (_stagedItems[i] == null) {
              _stagedItems[i] = dirName;
              break;
            }
            if(i==totalSquares-1){
              isSpace = true;
            }
          }
        });
        if(isSpace){
          _addToHistory('エラー: "$dirName"を配置するスペースが存在しません。');
        }else{
          _addToHistory('プレイヤー: mkdir $dirName');
        }
      }
    } else if (rmRegex.hasMatch(input)) {
      String dirName = rmRegex.firstMatch(input)!.group(1)!;
      if (_stagedItems.values.contains(dirName)) {
        setState(() {
          int targetIndex = _stagedItems.keys.firstWhere((index) => _stagedItems[index] == dirName);
          if (targetIndex == playerPosition) {
            _endGame('Defeat...');
          } else if (targetIndex == enemyPosition) {
            _endGame('Win!');
          } else {
            _stagedItems[targetIndex] = null;
          }
        });
        _addToHistory('プレイヤー: rm $dirName');
      } else {
        _addToHistory('エラー: "$dirName" は存在しません。');
      }
    } else if (cdRegex.hasMatch(input)) {
      String dirName = cdRegex.firstMatch(input)!.group(1)!;
      if (_stagedItems.values.contains(dirName)) {
        setState(() {
          playerPosition = _stagedItems.keys.firstWhere((index) => _stagedItems[index] == dirName);
        });
        _addToHistory('プレイヤー: cd $dirName');
      } else {
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
          String dirName = String.fromCharCode(targetIndex+97);
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
            command = 'cd ${_stagedItems[targetIndex]}';
          });
        }
        break;
    }

    if (command != null) {
      _addToHistory('敵: $command'); // デバッグ用
    }

    // プレイヤーのターンに移行
    setState(() {
      isPlayerTurn = true;
    });
  }

  void _endGame(String result) {
    setState(() {
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
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white), // 白色
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TitleScreen()),
                ),
                child: const Text('タイトルに戻る[t]'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MkdirApp()),
                ),
                child: const Text('もう一度遊ぶ[r]'),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount, // 四角形を縮小するために列の数を増やす
                crossAxisSpacing: crossAxisSpacing, // 列間の間隔
                mainAxisSpacing: mainAxisSpacing, // 行間の間隔
              ),
              itemCount: totalSquares,
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
                          fontSize: 14,
                          color: Colors.black, //四角形のテキストの色
                      ),

                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: historyHeight,
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
              hintText: 'mkdir:作成, rm:削除, cd:移動, ls:表示, exit:終了',
              hintStyle: TextStyle(color: Colors.green), // プレースホルダーの色
            ),
            onSubmitted: _handlePlayerCommand,
          ),
        ],
      ),
    );
  }
}