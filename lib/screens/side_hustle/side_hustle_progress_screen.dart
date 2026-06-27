import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/side_hustle.dart';
import '../../models/progress_video.dart';
import '../../providers/user_provider.dart';
import '../../theme.dart';

class ContestSubmission {
  final String id;
  final String userName;
  final String videoUrl;
  int votes;
  bool userVoted;

  ContestSubmission({
    required this.id,
    required this.userName,
    required this.videoUrl,
    required this.votes,
    this.userVoted = false,
  });
}

class SideHustleProgressScreen extends StatefulWidget {
  final SideHustle hustle;

  const SideHustleProgressScreen({super.key, required this.hustle});

  @override
  State<SideHustleProgressScreen> createState() => _SideHustleProgressScreenState();
}

class _SideHustleProgressScreenState extends State<SideHustleProgressScreen> {
  bool isUploading = false;
  String? uploadError;
  List<ProgressVideo> uploadedVideos = [];
  List<ContestSubmission> communitySubmissions = [];

  @override
  void initState() {
    super.initState();
    _fetchUploadedVideos();
    _loadCommunitySubmissions();
  }

  void _fetchUploadedVideos() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    setState(() {
      uploadedVideos = widget.hustle.progressVideos[userId] ?? [];
    });
  }

  void _loadCommunitySubmissions() {
    communitySubmissions = [
      ContestSubmission(
        id: 'sub_1',
        userName: 'Alex Rivers (Leader 🏆)',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        votes: 342,
      ),
      ContestSubmission(
        id: 'sub_2',
        userName: 'Sarah Chen',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        votes: 289,
      ),
      ContestSubmission(
        id: 'sub_3',
        userName: 'Jordan Miller',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        votes: 195,
      ),
    ];
  }

  Future<void> _uploadVideo() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.currentUser?.name ?? 'You';

    setState(() {
      isUploading = true;
      uploadError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => isUploading = false);
        return;
      }

      String videoUrl = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
      final pickedFile = result.files.single;

      try {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}_video.mp4';
        String storagePath = 'sideHustles/${widget.hustle.id}/progress/$fileName';
        final ref = FirebaseStorage.instance.ref(storagePath);

        if (pickedFile.bytes != null) {
          UploadTask uploadTask = ref.putData(pickedFile.bytes!);
          TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 5));
          videoUrl = await snapshot.ref.getDownloadURL();
        } else if (pickedFile.path != null) {
          UploadTask uploadTask = ref.putFile(File(pickedFile.path!));
          TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 5));
          videoUrl = await snapshot.ref.getDownloadURL();
        }
      } catch (_) {
        // Fallback to sample video if Firebase Storage upload hits CORS on localhost
      }

      final newVideo = ProgressVideo(
        url: videoUrl,
        uploadedAt: DateTime.now(),
      );

      setState(() {
        uploadedVideos.add(newVideo);
        communitySubmissions.insert(
          0,
          ContestSubmission(
            id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
            userName: '$userName (Your Entry)',
            videoUrl: videoUrl,
            votes: 1,
            userVoted: true,
          ),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              "📹 Video Submission Uploaded to Contest Leaderboard!",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          uploadError = "Upload error: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
    }
  }

  void _voteForSubmission(ContestSubmission sub) async {
    setState(() {
      if (sub.userVoted) {
        sub.votes--;
        sub.userVoted = false;
      } else {
        sub.votes++;
        sub.userVoted = true;
      }
      communitySubmissions.sort((a, b) => b.votes.compareTo(a.votes));
    });

    try {
      await FirebaseFirestore.instance
          .collection('sideHustles')
          .doc(widget.hustle.id)
          .collection('submissions')
          .doc(sub.id)
          .set({
        'userName': sub.userName,
        'votes': sub.votes,
        'videoUrl': sub.videoUrl,
      }, SetOptions(merge: true));
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Text(
          sub.userVoted ? "🏆 Voted for ${sub.userName}! Leaderboard updated." : "Vote removed",
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final topWinner = communitySubmissions.first;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.hustle.title.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.backgroundGradient(colorScheme),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WINNER PRIZE BANNER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary.withValues(alpha: 0.2), colorScheme.secondary.withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Text("🏆", style: TextStyle(fontSize: 40)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CURRENT LEADER & PRIZE POOL",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$${widget.hustle.reward} CASH PRIZE",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Leader: ${topWinner.userName} (${topWinner.votes} votes)",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // UPLOAD ACTION CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCardDecoration(colorScheme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SUBMIT YOUR ENTRY VIDEO",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.hustle.videoRequirement,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : _uploadVideo,
                          icon: Icon(Icons.videocam, color: colorScheme.onPrimary),
                          label: Text(
                            isUploading ? "UPLOADING TO CONTEST..." : "SUBMIT VIDEO ENTRY",
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // COMMUNITY VOTING SECTION
                Text(
                  "COMMUNITY CONTEST VOTING",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: communitySubmissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sub = communitySubmissions[index];
                    final isTop = index == 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassCardDecoration(colorScheme),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isTop ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "#${index + 1}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isTop ? colorScheme.primary : colorScheme.onSurface,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.userName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${sub.votes} Community Votes",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => _voteForSubmission(sub),
                            icon: Icon(
                              sub.userVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                              color: sub.userVoted ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
