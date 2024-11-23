import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final List<dynamic> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int score = 0;

  void _submitAnswer(String selectedAnswer) {
    final correctAnswer =
        widget.questions[currentQuestionIndex]['correct_answer'];

    if (selectedAnswer == correctAnswer) {
      setState(() {
        score++;
      });
    }

    if (currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      // Quiz 结束
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) =>
      //         ResultPage(score: score, total: widget.questions.length),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentQuestionIndex + 1}/${widget.questions.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              question['question'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...List<Widget>.from(
              (question['incorrect_answers'] as List<dynamic>)
                  .map((answer) => ElevatedButton(
                        onPressed: () => _submitAnswer(answer),
                        child: Text(answer),
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
