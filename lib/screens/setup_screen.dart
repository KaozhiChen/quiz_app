import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../services/api_service.dart';
import 'quiz_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late Future<List<Category>> futureCategories;
  Category? selectedCategory;
  String selectedDifficulty = 'medium';
  String selectedType = 'multiple';
  int selectedNumQuestions = 10;

  @override
  void initState() {
    super.initState();
    futureCategories = ApiService.fetchCategories();
  }

  // fetch questions and navigate to quiz screen
  void _startQuiz() async {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    try {
      // get questions
      final questions = await ApiService.fetchQuestions(
        amount: selectedNumQuestions,
        category: selectedCategory!.id,
        difficulty: selectedDifficulty,
        type: selectedType,
      );

      // navigate to quiz screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(questions: questions),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // category
            const Text('Select Category:'),
            FutureBuilder<List<Category>>(
              future: futureCategories,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No categories available');
                } else {
                  return DropdownButton<Category>(
                    hint: const Text('Select Category'),
                    value: selectedCategory,
                    isExpanded: true,
                    items: snapshot.data!.map((Category category) {
                      return DropdownMenuItem<Category>(
                        value: category,
                        child: Text(category.name),
                      );
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            // difficulty
            const Text('Select Difficulty:'),
            DropdownButton<String>(
              value: selectedDifficulty,
              isExpanded: true,
              items: ['easy', 'medium', 'hard'].map((String difficulty) {
                return DropdownMenuItem<String>(
                  value: difficulty,
                  child: Text(
                      difficulty[0].toUpperCase() + difficulty.substring(1)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDifficulty = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // question type
            const Text('Select Question Type:'),
            DropdownButton<String>(
              value: selectedType,
              isExpanded: true,
              items: [
                {'value': 'multiple', 'label': 'Multiple Choice'},
                {'value': 'boolean', 'label': 'True/False'},
              ].map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedType = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // number of questions
            const Text('Select Number of Questions:'),
            DropdownButton<int>(
              value: selectedNumQuestions,
              isExpanded: true,
              items: [5, 10, 15, 20].map((int num) {
                return DropdownMenuItem<int>(
                  value: num,
                  child: Text(num.toString()),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  selectedNumQuestions = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startQuiz,
                  child: const Text('Start Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
