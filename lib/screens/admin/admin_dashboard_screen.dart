import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../models/app_user.dart';
import '../../models/challenge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
      ),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabButton("Users", 0, theme, colorScheme),
              _buildTabButton("Challenges", 1, theme, colorScheme),
              _buildTabButton("Flagged", 2, theme, colorScheme),
            ],
          ),
          // Tab Content
          Expanded(
            child:
                _selectedTab == 0
                    ? _buildUsersTab()
                    : _selectedTab == 1
                    ? _buildChallengesTab()
                    : _buildFlaggedTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    String label,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color:
              _selectedTab == index
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No users found",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final users =
            snapshot.data!.docs
                .map(
                  (doc) => AppUser.fromMap(doc.data() as Map<String, dynamic>),
                )
                .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            // Store ScaffoldMessengerState before async operation
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            return Card(
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.avatar.startsWith('http')
                          ? NetworkImage(user.avatar)
                          : const AssetImage('assets/images/avatar.png')
                              as ImageProvider,
                ),
                title: Text(
                  user.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing:
                    user.isBanned
                        ? TextButton(
                          onPressed: () async {
                            await _authService.unbanUser(user.id);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text("${user.name} unbanned"),
                                backgroundColor: colorScheme.secondary,
                              ),
                            );
                          },
                          child: Text(
                            "Unban",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.secondary,
                            ),
                          ),
                        )
                        : TextButton(
                          onPressed: () async {
                            await _authService.banUser(user.id);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text("${user.name} banned"),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          },
                          child: Text(
                            "Ban",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChallengesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.firestore.collection('challenges').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No challenges found",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final challenges =
            snapshot.data!.docs
                .map(
                  (doc) =>
                      Challenge.fromMap(doc.data() as Map<String, dynamic>),
                )
                .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: challenges.length,
          itemBuilder: (context, index) {
            final challenge = challenges[index];
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            // Store ScaffoldMessengerState before async operation
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            return Card(
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: ListTile(
                title: Text(
                  challenge.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "${challenge.participants.length} participants",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await _authService.deleteChallenge(challenge.id);
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("${challenge.name} deleted"),
                        backgroundColor: colorScheme.error,
                      ),
                    );
                  },
                  child: Text(
                    "Delete",
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFlaggedTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            tabs: [
              Tab(
                child: Text(
                  "Flagged Users",
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Tab(
                child: Text(
                  "Reported Posts",
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildFlaggedUsers(), _buildReportedPosts()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedUsers() {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.firestore.collection('flagged_users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No flagged users",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final flaggedUsers = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flaggedUsers.length,
          itemBuilder: (context, index) {
            final doc = flaggedUsers[index];
            final userId = doc.id;
            final reason = doc['reason'] ?? 'No reason provided';
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            // Store ScaffoldMessengerState before async operation
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            return Card(
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: ListTile(
                title: Text(
                  "User ID: $userId",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _authService.banUser(userId);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text("User $userId banned"),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      },
                      child: Text(
                        "Ban",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _authService.dismissFlag(userId);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text("Flag for user $userId dismissed"),
                            backgroundColor: colorScheme.secondary,
                          ),
                        );
                      },
                      child: Text(
                        "Dismiss",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportedPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _authService.firestore.collection('reported_posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No reported posts",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final reportedPosts = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reportedPosts.length,
          itemBuilder: (context, index) {
            final doc = reportedPosts[index];
            final postId = doc['postId'] ?? '';
            final reason = doc['reason'] ?? 'No reason provided';
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            // Store ScaffoldMessengerState before async operation
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            return Card(
              color: colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
              child: ListTile(
                title: Text(
                  "Post ID: $postId",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await _authService.deletePost(postId);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text("Post $postId deleted"),
                            backgroundColor: colorScheme.error,
                          ),
                        );
                      },
                      child: Text(
                        "Delete",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _authService.dismissReportedPost(postId);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text("Report for post $postId dismissed"),
                            backgroundColor: colorScheme.secondary,
                          ),
                        );
                      },
                      child: Text(
                        "Dismiss",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
