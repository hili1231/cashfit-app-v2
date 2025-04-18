import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/side_hustle.dart';
import '../../models/progress_video.dart';

class SideHustleProgressScreen extends StatefulWidget {
  final SideHustle hustle;

  const SideHustleProgressScreen({super.key, required this.hustle});

  @override
  State<SideHustleProgressScreen> createState() =>
      _SideHustleProgressScreenState();
}

class _SideHustleProgressScreenState extends State<SideHustleProgressScreen> {
  bool isUploading = false;
  String? uploadError;
  List<ProgressVideo> uploadedVideos = [];

  @override
  void initState() {
    super.initState();
    _fetchUploadedVideos();
  }

  void _fetchUploadedVideos() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      uploadedVideos = widget.hustle.progressVideos[userId] ?? [];
    });
  }

  Future<void> _uploadVideo() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      isUploading = true;
      uploadError = null;
    });

    try {
      // Pick a video file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result == null || result.files.single.path == null) {
        if (mounted) {
          setState(() {
            isUploading = false;
            uploadError = "No video selected";
          });
        }
        return;
      }

      File videoFile = File(result.files.single.path!);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
      String storagePath =
          'sideHustles/${widget.hustle.id}/progress/$userId/$fileName';

      // Upload to Firebase Storage
      UploadTask uploadTask = FirebaseStorage.instance
          .ref(storagePath)
          .putFile(videoFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create a new ProgressVideo entry
      final newVideo = ProgressVideo(
        url: downloadUrl,
        uploadedAt: DateTime.now(),
      );

      // Update the progressVideos map in the SideHustle object
      final updatedProgressVideos = Map<String, List<ProgressVideo>>.from(
        widget.hustle.progressVideos,
      );
      if (!updatedProgressVideos.containsKey(userId)) {
        updatedProgressVideos[userId] = [];
      }
      updatedProgressVideos[userId]!.add(newVideo);

      // Update Firestore with the new progressVideos map
      await FirebaseFirestore.instance
          .collection('sideHustles')
          .doc(widget.hustle.id)
          .update({
            'progressVideos': updatedProgressVideos.map(
              (userId, videos) =>
                  MapEntry(userId, videos.map((v) => v.toMap()).toList()),
            ),
          });

      // Update the local state
      if (mounted) {
        setState(() {
          uploadedVideos = updatedProgressVideos[userId]!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Text(
              "Video uploaded successfully!",
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
        setState(() {
          uploadError = "Upload failed: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              "Upload failed: $e",
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
        setState(() => isUploading = false);
      }
    }
  }

  Future<void> _launchVideoUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text(
              "Could not launch video URL",
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.hustle.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload your progress videos for "${widget.hustle.title}"',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: theme.elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.all(colorScheme.primary),
                  foregroundColor: WidgetStateProperty.all(
                    colorScheme.onPrimary,
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                ),
                onPressed: isUploading ? null : _uploadVideo,
                icon: Icon(Icons.upload_file, color: colorScheme.onPrimary),
                label: Text(
                  isUploading ? "Uploading..." : "Upload Video",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (uploadError != null) ...[
                const SizedBox(height: 10),
                Text(
                  uploadError!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                "Your Uploaded Videos",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    uploadedVideos.isEmpty
                        ? Center(
                          child: Text(
                            "No videos uploaded yet.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                        : ListView.builder(
                          itemCount: uploadedVideos.length,
                          itemBuilder: (context, index) {
                            final video = uploadedVideos[index];
                            return Card(
                              elevation: 1,
                              color: colorScheme.surfaceContainer,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  "Video ${index + 1}",
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  "Uploaded on ${video.uploadedAt.toString()}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.play_arrow,
                                  color: colorScheme.primary,
                                ),
                                onTap: () => _launchVideoUrl(video.url),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
