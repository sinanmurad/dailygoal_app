import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: unused_import
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
export 'loading_widget.dart';

// Responsive NuvanaButton da güncellensin
class NuvanaButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final IconData? icon;

  const NuvanaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color ?? theme.colorScheme.primary,
            side: BorderSide(color: color ?? theme.colorScheme.primary),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: isSmallScreen ? 8 : 12,
            ),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: color ?? theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: isSmallScreen ? 8 : 12,
            ),
          );

    final buttonText = Text(
      text,
      style: TextStyle(
        fontSize: isSmallScreen ? 12 : 14,
        fontWeight: FontWeight.w500,
      ),
    );

    final buttonIcon = isLoading
        ? SizedBox(
            width: isSmallScreen ? 16 : 20,
            height: isSmallScreen ? 16 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined
                    ? (color ?? theme.colorScheme.primary)
                    : Colors.white,
              ),
            ),
          )
        : (icon != null
            ? Icon(icon, size: isSmallScreen ? 16 : 20)
            : const SizedBox.shrink());

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: buttonIcon,
        label: buttonText,
        style: buttonStyle,
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: buttonIcon,
      label: buttonText,
      style: buttonStyle,
    );
  }
}

// Responsive TaskCard - Güncellenmiş shared/widgets/widgets.dart içindeki TaskCard
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final bool showCompleteButton;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.showCompleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 300;

    return Card(
      elevation: isSmallScreen ? 2 : 4,
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: isSmallScreen ? 4 : 8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve Kategori - Responsive Layout
              isVerySmallScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getCategoryIcon(isSmallScreen),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Text(
                                task.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: isSmallScreen ? 14 : 18,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (task.isCompleted) ...[
                          const SizedBox(height: 8),
                          _getCompletedBadge(isSmallScreen),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        _getCategoryIcon(isSmallScreen),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: isSmallScreen ? 14 : 18,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (task.isCompleted) _getCompletedBadge(isSmallScreen),
                      ],
                    ),

              SizedBox(height: isSmallScreen ? 8 : 12),

              // Açıklama - Responsive
              Text(
                task.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                maxLines: isSmallScreen ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: isSmallScreen ? 8 : 12),

              // Alt bilgiler - Responsive Layout
              isVerySmallScreen
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getDifficultyChip(theme, isSmallScreen),
                            const SizedBox(width: 8),
                            _getPointsChip(theme, isSmallScreen),
                          ],
                        ),
                        if (task.deadline != null) ...[
                          const SizedBox(height: 8),
                          _getDeadlineInfo(theme, isSmallScreen),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        _getDifficultyChip(theme, isSmallScreen),
                        const SizedBox(width: 8),
                        _getPointsChip(theme, isSmallScreen),
                        const Spacer(),
                        if (task.deadline != null)
                          _getDeadlineInfo(theme, isSmallScreen),
                      ],
                    ),

              // Tamamla Butonu - Responsive
              if (showCompleteButton &&
                  !task.isCompleted &&
                  onComplete != null) ...[
                SizedBox(height: isSmallScreen ? 8 : 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: Icon(Icons.check, size: isSmallScreen ? 16 : 20),
                    label: Text(
                      'Tamamla',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon(bool isSmall) {
    IconData iconData;
    Color color;

    switch (task.category) {
      case TaskCategory.fitness:
        iconData = FontAwesomeIcons.dumbbell;
        color = Colors.red;
        break;
      case TaskCategory.learning:
        iconData = FontAwesomeIcons.book;
        color = Colors.blue;
        break;
      case TaskCategory.creativity:
        iconData = FontAwesomeIcons.palette;
        color = Colors.purple;
        break;
      case TaskCategory.social:
        iconData = FontAwesomeIcons.users;
        color = Colors.green;
        break;
      case TaskCategory.productivity:
        iconData = FontAwesomeIcons.briefcase;
        color = Colors.orange;
        break;
      case TaskCategory.health:
        iconData = FontAwesomeIcons.heartPulse;
        color = Colors.pink;
        break;
      default:
        iconData = FontAwesomeIcons.star;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(isSmall ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
      ),
      child: FaIcon(
        iconData,
        size: isSmall ? 12 : 16,
        color: color,
      ),
    );
  }

  Widget _getDifficultyChip(ThemeData theme, bool isSmall) {
    String text;
    Color color;

    switch (task.difficulty) {
      case TaskDifficulty.easy:
        text = 'Kolay';
        color = Colors.green;
        break;
      case TaskDifficulty.medium:
        text = 'Orta';
        color = Colors.orange;
        break;
      case TaskDifficulty.hard:
        text = 'Zor';
        color = Colors.red;
        break;
      case TaskDifficulty.expert:
        text = 'Uzman';
        color = Colors.purple;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: isSmall ? 10 : 12,
        ),
      ),
    );
  }

  Widget _getPointsChip(ThemeData theme, bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: isSmall ? 10 : 14,
            color: Colors.amber,
          ),
          SizedBox(width: isSmall ? 2 : 4),
          Text(
            '${task.points}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCompletedBadge(bool isSmall) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
      ),
      child: Text(
        'Tamamlandı',
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmall ? 9 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _getDeadlineInfo(ThemeData theme, bool isSmall) {
    if (task.deadline == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final timeLeft = task.deadline!.difference(now);
    Color deadlineColor;

    if (timeLeft.inHours < 24) {
      deadlineColor = Colors.red;
    } else if (timeLeft.inDays < 3) {
      deadlineColor = Colors.orange;
    } else {
      deadlineColor = theme.colorScheme.onSurface;
    }

    return Text(
      'Bitiş: ${task.deadline!.day}/${task.deadline!.month}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: deadlineColor,
        fontSize: isSmall ? 10 : 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(challenge.title),
        subtitle: Text(challenge.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (challenge.status == ChallengeStatus.pending && onAccept != null)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: onAccept,
              ),
            if (challenge.status == ChallengeStatus.pending && onReject != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onReject,
              ),
          ],
        ),
      ),
    );
  }
}
