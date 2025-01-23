import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TitleScreen(),
    );
  }
}

class TitleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'COMMAND BATTLE',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MkdirApp()),
                );
              },
              child: Text(
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
  @override
  _MkdirAppState createState() => _MkdirAppState();
}

class _MkdirAppState extends State<MkdirApp> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Map<int, String?> _items = {};
  final List<String> _history = [];
  final ScrollController _scrollController = ScrollController();

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
      List<String> alphabet = List.generate(25, (index) => String.fromCharCode(97 + index));
      for (int i = 0; i < alphabet.length; i++) {
        _items[i] = alphabet[i];
      }

      // プレイヤーと敵の初期位置を設定
      playerPosition = 0; // プレイヤーは左上
      _items[playerPosition] = 'プレイヤー';

      Random random = Random();
      do {
        enemyPosition = random.nextInt(25); // 敵はランダム位置
      } while (enemyPosition == playerPosition); // プレイヤーの位置と被らないように
      _items[enemyPosition] = '敵';
    });
  }

  void _addToHistory(String message) {
    setState(() {
      _history.add(message);
      if (_scrollController.hasClients) {
        Future.delayed(Duration(milliseconds: 100), () {
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
        _showErrorDialog(message: 'エラー: "${dirName}" は既に存在しています。');
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
        _showErrorDialog(message: 'エラー: "${dirName}" は存在しません。');
      }
    } else if (cdRegex.hasMatch(input)) {
      String dirName = cdRegex.firstMatch(input)!.group(1)!;
      if (_items.values.contains(dirName)) {
        setState(() {
          playerPosition = _items.keys.firstWhere((index) => _items[index] == dirName);
        });
        _addToHistory('プレイヤー: cd $dirName');
      } else {
        _showErrorDialog(message: 'エラー: "${dirName}" は存在しません。');
      }
    } else {
      _showErrorDialog(
          message: 'コマンドは以下の形式で入力してください:\n1. mkdir [名前]\n2. rm [名前]\n3. cd [名前]');
    }

    _controller.clear();
    _focusNode.requestFocus();

    // プレイヤーのターンが終了したら敵のターンを開始
    setState(() {
      isPlayerTurn = false;
    });
    Future.delayed(Duration(seconds: 1), _handleEnemyTurn);
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
          String dirName = '敵_${targetIndex}';
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

  void _showErrorDialog({required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Game Over'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                gameResult,
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => TitleScreen()),
                ),
                child: Text('タイトルに戻る'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MkdirApp()),
                ),
                child: Text('もう一度遊ぶ'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('COMMAND BATTLE'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),
              itemCount: 25,
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
                  margin: EdgeInsets.all(2),
                  color: squareColor,
                  child: Center(
                    child: Text(
                      _items[index] ?? '',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 40, // 履歴欄の高さ
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
            decoration: InputDecoration(hintText: 'コマンドを入力してください'),
            onSubmitted: _handlePlayerCommand,
          ),
        ],
      ),
    );
  }
}
