import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

import '../database_helper.dart';

class QuizScreen extends StatefulWidget {
  final List<dynamic> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  bool isAnswered = false;
  Map<String, IconData?> optionIcons = {};
  late Timer timer;
  int timeLeft = 20;
  List<String> shuffledAnswers = [];
  String questionText = '';

  @override
  void initState() {
    super.initState();
    loadQuestion();
    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void startTimer() {
    timeLeft = 20;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          _submitAnswer(null);
        }
      });
    });
  }

  void loadQuestion() {
    final question = widget.questions[currentQuestionIndex];
    final unescape = HtmlUnescape();

    questionText = unescape.convert(question['question']);
    final answers = [
      ...question['incorrect_answers'],
      question['correct_answer'],
    ].map((answer) => unescape.convert(answer)).toList();

    // shuffle answers
    answers.shuffle();

    setState(() {
      isAnswered = false;
      shuffledAnswers = answers;
      optionIcons = {for (var answer in answers) answer: null};
    });
  }

  void _submitAnswer(String? selectedAnswer) {
    final correctAnswer =
        widget.questions[currentQuestionIndex]['correct_answer'];

    setState(() {
      isAnswered = true;
      timer.cancel();

      if (selectedAnswer == null) {
        //
        optionIcons[correctAnswer] = Icons.check;
      } else {
        optionIcons[selectedAnswer] =
            selectedAnswer == correctAnswer ? Icons.check : Icons.close;
        optionIcons[correctAnswer] = Icons.check;
      }

      // update score
      if (selectedAnswer == correctAnswer) {
        score++;
      }
    });

    // go to next question
    Future.delayed(const Duration(seconds: 2), () {
      if (currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
        loadQuestion();
        startTimer();
      } else {
        _showResultDialog();
      }
    });
  }

  void _showLeaderboard() async {
    final leaderboard =
        await DatabaseHelper().getLeaderboard('Category'); // 替换为实际分类

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leaderboard'),
          content: leaderboard.isEmpty
              ? const Text('No scores yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: leaderboard.map((entry) {
                    return ListTile(
                      title: Text(entry['username']),
                      trailing: Text(entry['score'].toString()),
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close leaderboard
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('Back to Setup'),
            ),
          ],
        );
      },
    );
  }

  void _showResultDialog() async {
    TextEditingController usernameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Completed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You scored $score out of ${widget.questions.length}'),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String username = usernameController.text.trim();
                if (username.isNotEmpty) {
                  // Save to leaderboard
                  await DatabaseHelper().insertScore(
                    username,
                    'Category', // 替换为实际分类
                    score,
                  );

                  Navigator.pop(context); // Close dialog
                  _showLeaderboard(); // Show leaderboard
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // progress
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.questions.length,
            ),
            const SizedBox(height: 20),

            // timer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${currentQuestionIndex + 1}/${widget.questions.length}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Time Left: $timeLeft s',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // questions
            Text(
              questionText,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // choices
            Expanded(
              child: ListView.builder(
                itemCount: shuffledAnswers.length,
                itemBuilder: (context, index) {
                  final answer = shuffledAnswers[index];
                  return Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: Icon(
                        optionIcons[answer],
                        color: optionIcons[answer] == Icons.check
                            ? Colors.green
                            : (optionIcons[answer] == Icons.close
                                ? Colors.red
                                : null),
                      ),
                      title: Text(answer),
                      onTap: isAnswered ? null : () => _submitAnswer(answer),
                    ),
                  );
                },
              ),
            ),

            // score
            Text(
              'Score: $score',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
