import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TitleScreen(), // 初期画面をタイトル画面に設定
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
                // ボタンを押すとゲーム画面に遷移
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
  final FocusNode _focusNode = FocusNode(); // フォーカスノードを作成
  final Map<int, String?> _items = {}; // インデックスと名前のマップ
  int playerPosition = 0; // プレイヤーの位置を保持
  bool isGameOver = false; // ゲームオーバーフラグ

  @override
  void initState() {
    super.initState();
    _initializeSquares();
    // アプリ起動時に自動的に入力欄にフォーカスを当てる
    _focusNode.requestFocus();
  }

  void _initializeSquares() {
    // ゲームが開始したときに状態をリセット
    setState(() {
      isGameOver = false;
      _items.clear();
      // a〜y (25文字) を作成
      List<String> alphabet = List.generate(25, (index) => String.fromCharCode(97 + index));
      for (int i = 0; i < alphabet.length; i++) {
        _items[i] = alphabet[i];
      }
      // プレイヤーは一番左上の四角形として緑色にする
      _items[0] = 'プレイヤー';  // プレイヤーの名前
      playerPosition = 0;  // プレイヤーの位置
    });
  }

  void _handleExecute() {
    String input = _controller.text.trim();
    final mkdirRegex = RegExp(r'^mkdir\s+(.+)$');
    final rmRegex = RegExp(r'^rm\s+(.+)$');
    final cdRegex = RegExp(r'^cd\s+(.+)$'); // cdコマンド用の正規表現

    if (mkdirRegex.hasMatch(input)) {
      String dirName = mkdirRegex.firstMatch(input)!.group(1)!;

      // すでに作成済みの名前があるか確認
      if (_items.values.contains(dirName)) {
        _showErrorDialog(message: 'エラー: すでに "${dirName}" は作成されています。');
        return;
      }

      setState(() {
        // 空いている最初のインデックスに追加
        for (int i = 0; i < 100; i++) {
          if (_items[i] == null) {
            _items[i] = dirName;
            break;
          }
        }
      });
      _controller.clear();
    } else if (rmRegex.hasMatch(input)) {
      String dirName = rmRegex.firstMatch(input)!.group(1)!;

      setState(() {
        // 名前が一致する最初のアイテムを削除
        for (int i = 0; i < _items.length; i++) {
          if (_items[i] == dirName) {
            if (i == playerPosition) {
              // プレイヤーがいる四角形が削除された場合
              isGameOver = true;
            }
            _items[i] = null;
            break; // 最初に一致したものを削除したらループを抜ける
          }
        }
      });
      _controller.clear();
    } else if (cdRegex.hasMatch(input)) {
      String dirName = cdRegex.firstMatch(input)!.group(1)!;

      // 同じ名前の四角形が存在するか確認
      bool exists = _items.values.any((name) => name == dirName);
      if (exists) {
        setState(() {
          // プレイヤーを移動させる
          playerPosition = _items.keys.firstWhere((index) => _items[index] == dirName);
        });
        _controller.clear();
      } else {
        _showErrorDialog(message: 'エラー: "${dirName}" は存在しません。');
      }
    } else {
      _showErrorDialog(
          message: 'コマンドは以下の形式で入力してください:\n\n1. mkdir [ディレクトリ名]\n2. rm [ディレクトリ名]\n3. cd [ディレクトリ名]');
    }

    // 実行後にフォーカスをTextFieldに戻す
    FocusScope.of(context).requestFocus(_focusNode);
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

  void _resetGame() {
    // ゲームをリセット
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MkdirApp()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isGameOver) {
      // ゲームオーバー画面を表示
      return Scaffold(
        appBar: AppBar(
          title: Text('GAME OVER'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Game Over',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetGame,
                child: Text('タイトルに戻る'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _resetGame();
                  _initializeSquares();  // 初期化して再開
                },
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 横5列
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  if (_items.containsKey(index) && _items[index] != null) {
                    // プレイヤーの位置を反映
                    Color squareColor = index == playerPosition
                        ? Colors.green
                        : Colors.yellow; // プレイヤーの位置は緑色
                    return Container(
                      color: squareColor,
                      child: Center(
                        child: Text(
                          _items[index]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  } else {
                    return Container(); // 空の四角形
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode, // フォーカスノードを指定
              decoration: InputDecoration(
                hintText: '例: mkdir testDir または rm testDir または cd testDir',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (input) {
                // Enterキーが押された時にコマンドを実行
                _handleExecute();
              },
            ),
          ),
        ],
      ),
    );
  }
}
