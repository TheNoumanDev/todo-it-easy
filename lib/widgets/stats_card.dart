import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';
import '../utils/constants.dart';

class StatsCard extends StatelessWidget {
  final TodoStats stats;

  const StatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: AppConstants.titleStyle,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    stats.total,
                    Colors.grey[600]!,
                    Icons.list_alt,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'To Do',
                    stats.todo,
                    Colors.grey[600]!,
                    Icons.radio_button_unchecked,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'In Progress',
                    stats.inProgress,
                    Colors.blue[600]!,
                    Icons.play_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Pending',
                    stats.pending,
                    Colors.orange[600]!,
                    Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Done',
                    stats.completed,
                    Colors.green[600]!,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            if (stats.total > 0) ...[
              const SizedBox(height: 12),
              _buildProgressBar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: AppConstants.titleStyle.copyWith(
            color: color,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: AppConstants.captionStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final completionRate = stats.total > 0 ? stats.completed / stats.total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: AppConstants.subtitleStyle,
            ),
            Text(
              '${(completionRate * 100).toInt()}% Complete',
              style: AppConstants.captionStyle.copyWith(
                color: Colors.green[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: completionRate,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          minHeight: 6,
        ),
      ],
    );
  }
}