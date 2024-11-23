import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

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

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Completed!'),
          content: Text('You scored $score out of ${widget.questions.length}'),
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
