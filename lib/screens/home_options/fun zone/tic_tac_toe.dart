import 'package:flutter/material.dart';

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  _TicTacToeGameState createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> {
  List<String> board = List.filled(9, '');
  String currentPlayer = 'X';
  bool gameOver = false;

  // Handle user tapping a tile
  void _onTileTapped(int index) {
    if (gameOver || board[index] != '') return;

    setState(() {
      board[index] = currentPlayer;
      if (_checkWinner()) {
        gameOver = true;
        _showGameOverDialog('Player $currentPlayer wins!');
      } else if (!board.contains('')) {
        gameOver = true;
        _showGameOverDialog('It\'s a draw!');
      } else {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
      }
    });
  }

  // Check if there is a winner
  bool _checkWinner() {
    const winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];

    for (var pattern in winPatterns) {
      if (board[pattern[0]] != '' &&
          board[pattern[0]] == board[pattern[1]] &&
          board[pattern[0]] == board[pattern[2]]) {
        return true;
      }
    }
    return false;
  }

  // Show the game over dialog
  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(
            'Game Over',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[900],
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  board = List.filled(9, '');
                  gameOver = false;
                  currentPlayer = 'X';
                });
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: Text(
                'Restart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          backgroundColor: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tic Tac Toe Game',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        elevation: 4,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: LayoutBuilder( // Use LayoutBuilder
          builder: (BuildContext context, BoxConstraints constraints) {
            double boardSize =
                MediaQuery.of(context).size.width * 0.8; // 80% of screen width

            // Ensure the board isn't too large on very tall screens
            if (boardSize > constraints.maxHeight * 0.7) {
              boardSize = constraints.maxHeight * 0.7;
            }

            double tileSize = boardSize / 3;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game Board Grid
                Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _onTileTapped(index),
                        child: Container(
                          width: tileSize,
                          height: tileSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: Text(
                            board[index],
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.w600,
                              color: board[index] == 'X'
                                  ? Colors.indigo
                                  : Colors.deepOrange,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Player $currentPlayer\'s turn',
                  style: TextStyle(
                      fontSize: 24,
                      color: Colors.blueGrey[800],
                      fontWeight: FontWeight.w500),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}