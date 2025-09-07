import 'package:app/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/models/models.dart';

class HomeScreenKey extends StatefulWidget {
  const HomeScreenKey({super.key});

  @override
  State<HomeScreenKey> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenKey> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  String? _activeCommentChallengeId;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _loadFeed() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.loadPublicChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          _loadFeed();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 1,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flash_on,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Challenge Feed',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/challenge'),
                  icon: Icon(Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: 'Yeni Meydan Okuma',
                ),
              ],
            ),

            // Feed Content
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoadingPublic &&
                    taskProvider.publicChallenges.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (taskProvider.publicChallenges.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final challenge = taskProvider.publicChallenges[index];
                      return _buildChallengeCard(
                          challenge, authProvider.currentUser?.id ?? '');
                    },
                    childCount: taskProvider.publicChallenges.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz meydan okuma yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk meydan okumayı sen oluştur!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/challenge'),
            icon: const Icon(Icons.add),
            label: const Text('Meydan Okuma Oluştur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, String currentUserId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildChallengeHeader(challenge),

          // Content
          _buildChallengeContent(challenge),

          // Status Badge
          _buildStatusBadge(challenge),

          // Actions (Like, Comment)
          _buildActionButtons(challenge, currentUserId),

          // Comments Section
          if (_activeCommentChallengeId == challenge.id)
            _buildCommentsSection(challenge, currentUserId),
        ],
      ),
    );
  }

  Widget _buildChallengeHeader(Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Challenger Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(challenge.challengerId),
            ),
            child: Center(
              child: Text(
                challenge.challengerId.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Challenge Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                    children: [
                      TextSpan(
                        text: challenge.challengerId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: challenge.challengedId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '\'e meydan okudu'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(challenge.createdAt, locale: 'tr'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Category Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  _getCategoryColor(challenge.task.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _getCategoryIcon(challenge.task.category),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeContent(Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            challenge.task.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            challenge.task.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Task Info Row
          Row(
            children: [
              // Difficulty
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(challenge.task.difficulty)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getDifficultyColor(challenge.task.difficulty)
                        .withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDifficultyIcon(challenge.task.difficulty),
                      size: 14,
                      color: _getDifficultyColor(challenge.task.difficulty),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyName(challenge.task.difficulty),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getDifficultyColor(challenge.task.difficulty),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Points
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.task.points}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Deadline
              if (challenge.task.deadline != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.task.deadline!.day}/${challenge.task.deadline!.month}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Challenge challenge) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (challenge.status) {
      case ChallengeStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
        statusIcon = Icons.hourglass_empty;
        break;
      case ChallengeStatus.accepted:
        statusColor = Colors.blue;
        statusText = 'Kabul Edildi';
        statusIcon = Icons.play_arrow;
        break;
      case ChallengeStatus.completed:
        statusColor = Colors.green;
        statusText = 'Tamamlandı';
        statusIcon = Icons.celebration;
        break;
      case ChallengeStatus.rejected:
        statusColor = Colors.red;
        statusText = 'Reddedildi';
        statusIcon = Icons.close;
        break;
      case ChallengeStatus.expired:
        statusColor = Colors.grey;
        statusText = 'Süresi Dolmuş';
        statusIcon = Icons.timer_off;
        break;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          if (challenge.status == ChallengeStatus.completed) ...[
            const SizedBox(width: 8),
            const Text('🎉', style: TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(Challenge challenge, String currentUserId) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final isLiked =
            taskProvider.isChallengeLiked(challenge.id, currentUserId);
        final likeCount = taskProvider.getChallengeLikes(challenge.id);
        final commentCount =
            taskProvider.getChallengeComments(challenge.id).length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Like Button
              InkWell(
                onTap: () => taskProvider.toggleChallengeLike(
                    challenge.id, currentUserId),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? Colors.red : Colors.grey[600],
                      ),
                      if (likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          likeCount.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Comment Button
              InkWell(
                onTap: () => _toggleComments(challenge.id),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        commentCount > 0 ? commentCount.toString() : 'Yorum',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsSection(Challenge challenge, String currentUserId) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final comments = taskProvider.getChallengeComments(challenge.id);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              // Comments List
              if (comments.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _buildCommentItem(comment as ChallengeComment);
                    },
                  ),
                ),
              // Comment Input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Yorum yaz...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _addComment(challenge.id, currentUserId),
                    icon: Icon(Icons.send,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(ChallengeComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getAvatarColor(comment.username),
            ),
            child: Center(
              child: Text(
                comment.username.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    comment.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    timeago.format(comment.createdAt, locale: 'tr'),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[name.length % colors.length];
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.fitness:
        return Colors.red;
      case TaskCategory.learning:
        return Colors.blue;
      case TaskCategory.creativity:
        return Colors.purple;
      case TaskCategory.social:
        return Colors.green;
      case TaskCategory.productivity:
        return Colors.orange;
      case TaskCategory.health:
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  Widget _getCategoryIcon(TaskCategory category) {
    IconData icon;
    Color color = _getCategoryColor(category);

    switch (category) {
      case TaskCategory.fitness:
        icon = FontAwesomeIcons.dumbbell;
        break;
      case TaskCategory.learning:
        icon = FontAwesomeIcons.book;
        break;
      case TaskCategory.creativity:
        icon = FontAwesomeIcons.palette;
        break;
      case TaskCategory.social:
        icon = FontAwesomeIcons.users;
        break;
      case TaskCategory.productivity:
        icon = FontAwesomeIcons.briefcase;
        break;
      case TaskCategory.health:
        icon = FontAwesomeIcons.heartPulse;
        break;
      default:
        icon = FontAwesomeIcons.star;
    }

    return FaIcon(icon, color: color, size: 16);
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.expert:
        return Colors.purple;
    }
  }

  IconData _getDifficultyIcon(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Icons.sentiment_satisfied;
      case TaskDifficulty.medium:
        return Icons.sentiment_neutral;
      case TaskDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case TaskDifficulty.expert:
        return Icons.psychology;
    }
  }

  String _getDifficultyName(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Kolay';
      case TaskDifficulty.medium:
        return 'Orta';
      case TaskDifficulty.hard:
        return 'Zor';
      case TaskDifficulty.expert:
        return 'Uzman';
    }
  }

  void _toggleComments(String challengeId) {
    setState(() {
      if (_activeCommentChallengeId == challengeId) {
        _activeCommentChallengeId = null;
      } else {
        _activeCommentChallengeId = challengeId;
      }
    });
  }

  void _addComment(String challengeId, String currentUserId) {
    if (_commentController.text.trim().isEmpty) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    taskProvider.addChallengeComment(
      challengeId,
      _commentController.text.trim(),
      authProvider.currentUser?.username ?? 'Anonymous',
    );

    _commentController.clear();
  }
}
