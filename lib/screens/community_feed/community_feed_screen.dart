import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/post.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  CommunityFeedScreenState createState() => CommunityFeedScreenState();
}

class CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool isPosting = false;

  @override
  void initState() {
    super.initState();
    // Configure Firestore settings to use the main thread for callbacks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      FirebaseFirestore.instance.settings = FirebaseFirestore.instance.settings.copyWith(
        host: FirebaseFirestore.instance.settings.host,
        sslEnabled: FirebaseFirestore.instance.settings.sslEnabled,
        persistenceEnabled: FirebaseFirestore.instance.settings.persistenceEnabled,
      );
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    _commentController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<bool> _checkAndPromptForUsername(UserProvider userProvider) async {
    if (userProvider.currentUser == null) return false;

    final userName = userProvider.currentUser!.name;
    if (userName.trim().isEmpty) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              "Set Your Username",
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            content: TextField(
              controller: _usernameController,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "Enter your username",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "Cancel",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_usernameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: colorScheme.error,
                        content: Text(
                          "Username cannot be empty",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onError,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: Text(
                  "Set",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (result == true) {
        // Update the user's username in Firestore
        await _authService.updateUserFields(userProvider.currentUser!.id, {
          'name': _usernameController.text.trim(),
        });
        // Refresh user data without triggering navigation
        await userProvider.loadUserData(userProvider.currentUser!.id);
        return true;
      }
      return false;
    }
    return true;
  }

  Future<void> _createPost() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.currentUser == null) return;

    // Check if the user has a username
    final canProceed = await _checkAndPromptForUsername(userProvider);
    if (!canProceed) return;

    if (_postController.text.isEmpty) return;

    setState(() {
      isPosting = true;
    });

    try {
      await _authService.createPost(
        userId: userProvider.currentUser!.id,
        userName: userProvider.currentUser!.name,
        userAvatar: userProvider.currentUser!.avatar,
        content: _postController.text,
      );

      _postController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              "Post created successfully!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              "Failed to create post: $e",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final userProvider = Provider.of<UserProvider>(context);

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "COMMUNITY FEED",
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Post Creation Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _postController,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: "Share your progress...",
                          hintStyle: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        style: theme.elevatedButtonTheme.style?.copyWith(
                          backgroundColor: WidgetStateProperty.all(
                            colorScheme.primary,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            colorScheme.onPrimary,
                          ),
                        ),
                        onPressed: isPosting ? null : _createPost,
                        child:
                            isPosting
                                ? CircularProgressIndicator(
                                  color: colorScheme.onPrimary,
                                )
                                : Text(
                                  "Post",
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
                // Feed Section
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading posts: ${snapshot.error}",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        decoration: AppTheme.backgroundGradient(colorScheme),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    }
                    final posts = snapshot.data != null && snapshot.data!.docs.isNotEmpty
                        ? snapshot.data!.docs.map((doc) => Post.fromMap(doc.data())).toList()
                        : _getSampleCommunityPosts();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return _buildPostCard(
                          theme,
                          colorScheme,
                          posts[index],
                          userProvider,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImage(String? userAvatar) {
    if (userAvatar == null || userAvatar.trim().isEmpty) {
      return const AssetImage('assets/images/default_avatar_1.png');
    }

    if (userAvatar.startsWith('http') || userAvatar.startsWith('https')) {
      return CachedNetworkImageProvider(userAvatar);
    }

    return const AssetImage('assets/images/default_avatar_1.png');
  }

  Widget _buildPostCard(
    ThemeData theme,
    ColorScheme colorScheme,
    Post post,
    UserProvider userProvider,
  ) {
    final user = userProvider.currentUser;
    final isLiked = user != null && post.likes.contains(user.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.surface,
                  backgroundImage: _getAvatarImage(post.userAvatar),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child:
                      _getAvatarImage(post.userAvatar) == null
                          ? Icon(
                            Icons.person,
                            color: colorScheme.onSurfaceVariant,
                            size: 24,
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatTimestamp(post.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
                  placeholder:
                      (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Icon(
                        Icons.broken_image,
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color:
                            isLiked
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed:
                          user == null
                              ? null
                              : () async {
                                if (isLiked) {
                                  await _authService.unlikePost(
                                    post.id,
                                    user.id,
                                  );
                                } else {
                                  await _authService.likePost(post.id, user.id);
                                }
                              },
                    ),
                    Text(
                      "${post.likes.length} Likes",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.report,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed:
                      user == null
                          ? null
                          : () async {
                            final reason = await _showReportDialog(
                              theme,
                              colorScheme,
                            );
                            if (reason != null) {
                              await _authService.reportPost(
                                post.id,
                                user.id,
                                reason,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: colorScheme.primary,
                                    content: Text(
                                      "Post reported.",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onPrimary,
                                          ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                ),
              ],
            ),
            if (post.comments.isNotEmpty) ...[
              Divider(color: colorScheme.onSurfaceVariant),
              ...post.comments.map(
                (comment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        "${comment['userName']}: ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          comment['content'],
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    onPressed:
                        user == null || _commentController.text.isEmpty
                            ? null
                            : () async {
                              await _authService.addComment(
                                post.id,
                                user.id,
                                user.name,
                                _commentController.text,
                              );
                              _commentController.clear();
                            },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  Future<String?> _showReportDialog(
    ThemeData theme,
    ColorScheme colorScheme,
  ) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              "Report Post",
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            content: TextField(
              controller: controller,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: "Reason for reporting...",
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(
                  "Report",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  List<Post> _getSampleCommunityPosts() {
    return [
      Post(
        id: 'post_1',
        userId: 'user_alex',
        userName: 'Alex Rivers',
        userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        content: 'Crushed my 10,000 steps step goal for today! Earned 50 FitCoins. Who else is staying consistent this week? 🔥 💪',
        imageUrl: 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?auto=format&fit=crop&w=800&q=80',
        likes: ['u1', 'u2', 'u3', 'u4'],
        comments: [
          {'userName': 'Sarah Chen', 'content': 'Awesome work Alex! Keep pushing!'},
          {'userName': 'Jordan Miller', 'content': 'Let’s go!! 🔥'},
        ],
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Post(
        id: 'post_2',
        userId: 'user_sarah',
        userName: 'Sarah Chen',
        userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
        content: 'Just tried the Herbed Avocado Toast Deluxe recipe from the CashFit meal plan! Super delicious and macro-friendly. 🥑 🍞',
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80',
        likes: ['u1', 'u5', 'u6'],
        comments: [
          {'userName': 'Alex Rivers', 'content': 'That looks delicious!'},
        ],
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
