import 'package:flutter/material.dart';
import '../database_helper.dart';

class LeaderboardScreen extends StatelessWidget {
  final String category;

  const LeaderboardScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$category Leaderboard')),
      body: FutureBuilder(
        future: DatabaseHelper().getLeaderboard(category),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final leaderboard = snapshot.data as List<Map<String, dynamic>>;

          return ListView.builder(
            itemCount: leaderboard.length,
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              return ListTile(
                title: Text(entry['playerName']),
                subtitle: Text('Score: ${entry['score']}'),
                leading: CircleAvatar(child: Text('${index + 1}')),
              );
            },
          );
        },
      ),
    );
  }
}
