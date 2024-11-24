import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

import '../database_helper.dart';

class QuizScreen extends StatefulWidget {
  final List<dynamic> questions;
  final String category;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.category,
  });

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
  double progress = 1.0;

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
    progress = 1.0;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
          progress = timeLeft / 20;
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
    final leaderboard = await DatabaseHelper().getLeaderboard(widget.category);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${widget.category} Leaderboard'),
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
                Navigator.pop(context);
                Navigator.pop(context);
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
      barrierDismissible: false, // Prevent dismissal without input
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
            // Allow returning without saving score
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () async {
                String username = usernameController.text.trim();
                if (username.isNotEmpty) {
                  // Save to leaderboard
                  await DatabaseHelper().insertScore(
                    username,
                    widget.category,
                    score,
                  );

                  Navigator.pop(context);
                  _showLeaderboard();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty')),
                  );
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
                Row(
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.5
                              ? Colors.green
                              : (progress > 0.2 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Time Left: $timeLeft s',
                      style: const TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ],
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
