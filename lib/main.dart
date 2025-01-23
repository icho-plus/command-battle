import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black, // 背景を黒に設定
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // デフォルトのテキスト色を白に設定
        ),
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'COMMAND BATTLE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                //color: Colors.white, // 白色に設定
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MkdirApp()),
                );
              },
              child: const Text(
                '始める',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
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
  final Map<int, String?> _items = {};
  final List<String> _history = [];
  final ScrollController _scrollController = ScrollController();
  final int totalSquares = 21; // 四角形の総数
  final int crossAxisCount = 7; // 1行に表示する四角形の数
  final double crossAxisSpacing = 4; // 列間の間隔
  final double mainAxisSpacing = 4; // 行間の間隔

  int playerPosition = 0;
  int enemyPosition = 0;
  bool isGameOver = false;
  bool isPlayerTurn = true;
  String gameResult = '';


  @override
  void initState() {
    super.initState();
    _initializeGame();
    _focusNode.requestFocus();
  }

  void _initializeGame() {
    setState(() {
      isGameOver = false;
      isPlayerTurn = true;
      gameResult = '';
      _items.clear();
      _history.clear();

      // 初期の四角形を作成
      List<String> alphabet = List.generate(totalSquares, (index) => String.fromCharCode(97 + index));
      for (int i = 0; i < alphabet.length; i++) {
        _items[i] = alphabet[i];
      }

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

    if (mkdirRegex.hasMatch(input)) {
      String dirName = mkdirRegex.firstMatch(input)!.group(1)!;
      if (_items.values.contains(dirName)) {
        _addToHistory('エラー: "$dirName" は既に存在しています。');
      } else {
        setState(() {
          for (int i = 0; i < 100; i++) {
            if (_items[i] == null) {
              _items[i] = dirName;
              break;
            }
          }
        });
        _addToHistory('プレイヤー: mkdir $dirName');
      }
    } else if (rmRegex.hasMatch(input)) {
      String dirName = rmRegex.firstMatch(input)!.group(1)!;
      if (_items.values.contains(dirName)) {
        setState(() {
          int targetIndex = _items.keys.firstWhere((index) => _items[index] == dirName);
          if (targetIndex == playerPosition) {
            _endGame('あなたの負け');
          } else if (targetIndex == enemyPosition) {
            _endGame('あなたの勝ち');
          } else {
            _items[targetIndex] = null;
          }
        });
        _addToHistory('プレイヤー: rm $dirName');
      } else {
        _addToHistory('エラー: "$dirName" は存在しません。');
      }
    } else if (cdRegex.hasMatch(input)) {
      String dirName = cdRegex.firstMatch(input)!.group(1)!;
      if (_items.values.contains(dirName)) {
        setState(() {
          playerPosition = _items.keys.firstWhere((index) => _items[index] == dirName);
        });
        _addToHistory('プレイヤー: cd $dirName');
      } else {
        _addToHistory('エラー: "$dirName" は存在しません。');
      }
    } else {
      _addToHistory('エラー: コマンドは以下の形式で入力してください:\n1. mkdir [名前]\n2. rm [名前]\n3. cd [名前]');
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
    List<int> availableIndexes = _items.keys.where((index) => _items[index] == null).toList();
    List<int> removableIndexes = _items.keys
        .where((index) => index != enemyPosition && _items[index] != null)
        .toList();
    List<int> movableIndexes = _items.keys
        .where((index) => index != playerPosition && _items[index] != null)
        .toList();

    String? command;
    int actionType = random.nextInt(3); // 0: mkdir, 1: rm, 2: cd

    switch (actionType) {
      case 0: // mkdir
        if (availableIndexes.isNotEmpty) {
          int targetIndex = availableIndexes[random.nextInt(availableIndexes.length)];
          String dirName = '$targetIndex';
          setState(() {
            _items[targetIndex] = dirName;
            command = 'mkdir $dirName';
          });
        }
        break;

      case 1: // rm
        if (removableIndexes.isNotEmpty) {
          int targetIndex = removableIndexes[random.nextInt(removableIndexes.length)];
          String? dirName = _items[targetIndex];
          setState(() {
            if (targetIndex == playerPosition) {
              _endGame('あなたの負け');
            } else if (targetIndex == enemyPosition) {
              // 敵が自身の位置を削除しない
            } else {
              _items[targetIndex] = null;
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
            command = 'cd ${_items[targetIndex]}';
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
    setState(() {
      isGameOver = true;
      gameResult = result;
    });
  }

  // void _showErrorDialog({required String message}) {
  //   // エラーメッセージを履歴に追加
  //   _addToHistory('エラー: $message');
  //
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('エラー'),
  //       content: Text(message),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game Over'),
          backgroundColor: Colors.black, // AppBar背景色を黒に
        ),
        body: Center(
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
                child: const Text('タイトルに戻る'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MkdirApp()),
                ),
                child: const Text('もう一度遊ぶ'),
              ),
            ],
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
                  squareColor = Colors.red;
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
            height: 140, // 履歴欄の高さ
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
              hintText: 'コマンドを入力してください',
              hintStyle: TextStyle(color: Colors.green), // プレースホルダーの色
            ),
            onSubmitted: _handlePlayerCommand,
          ),
        ],
      ),
    );
  }
}
