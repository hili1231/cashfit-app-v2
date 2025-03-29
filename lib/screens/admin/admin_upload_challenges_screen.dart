import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart'; // (NEW) for date formatting

import '../../models/challenge.dart';
import '../../data/challenge_data.dart';

class AdminUploadChallengesScreen extends StatefulWidget {
  const AdminUploadChallengesScreen({super.key});

  @override
  State<AdminUploadChallengesScreen> createState() =>
      _AdminUploadChallengesScreenState();
}

class _AdminUploadChallengesScreenState
    extends State<AdminUploadChallengesScreen> {
  final _formKey = GlobalKey<FormState>();

  List<Challenge> _challenges = [];
  Challenge? _selectedChallenge;

  final nameController = TextEditingController();
  final descController = TextEditingController();
  final instructionController = TextEditingController();
  final prizeAmountController = TextEditingController();

  final maxParticipantsController = TextEditingController(); // (CHANGED)

  List<String> instructions = [];

  XFile? _selectedImage;
  String? _currentImageUrl;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('challenges').get();
      final List<Challenge> loaded =
          snapshot.docs.map((doc) => Challenge.fromMap(doc.data())).toList();
      if (mounted) {
        setState(() => _challenges = loaded);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load challenges: $e")));
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _onChallengeSelected(Challenge? challenge) {
    setState(() {
      _selectedChallenge = challenge;
      if (challenge != null) {
        nameController.text = challenge.name;
        descController.text = challenge.description;
        prizeAmountController.text = challenge.prizeAmount.toString();
        maxParticipantsController.text =
            challenge.maxParticipants?.toString() ?? "";
        instructions = List.from(challenge.instructions);
        _currentImageUrl = challenge.image;
        _selectedImage = null;
      } else {
        _clearForm();
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = picked);
  }

  Future<Object?> _compressImage(File file) async {
    // Skip compress if web or desktop
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return file;
    }
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );
  }

  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    // (NEW) Build the doc ID
    final String challengeId;
    if (_selectedChallenge != null) {
      // If editing, keep the existing doc ID
      challengeId = _selectedChallenge!.id;
    } else {
      // If creating new, build ID from name + date
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final nowStr = formatter.format(DateTime.now());
      final sanitizedName = nameController.text.trim().replaceAll(' ', '_');
      challengeId = '${sanitizedName}_$nowStr';
    }

    // Keep existing participants if editing, else empty
    final existingParticipants = _selectedChallenge?.participants ?? [];

    String imageUrl = _currentImageUrl ?? "default_url";

    if (_selectedImage != null) {
      try {
        final file = File(_selectedImage!.path);
        final compressed = await _compressImage(file);
        final ref = FirebaseStorage.instance.ref().child(
          "challenge_images/$challengeId.jpg",
        );
        await ref.putFile(compressed as File);
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
        setState(() => isLoading = false);
        return;
      }
    }

    final parsedMaxParticipants = int.tryParse(maxParticipantsController.text);

    final updatedChallenge = Challenge(
      id: challengeId,
      name: nameController.text,
      description: descController.text,
      image: imageUrl,
      participants: existingParticipants,
      prizeAmount: double.tryParse(prizeAmountController.text) ?? 0.0,
      instructions: instructions,
      progressVideos: _selectedChallenge?.progressVideos ?? {},
      maxParticipants: parsedMaxParticipants,
    );

    try {
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .set(updatedChallenge.toMap());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedChallenge != null
                ? "✅ Challenge updated!"
                : "✅ Challenge created!",
          ),
        ),
      );
      _clearForm();
      await _loadChallenges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _deleteChallenge() async {
    if (_selectedChallenge == null) return;
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(_selectedChallenge!.id)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Challenge deleted!")));
      _clearForm();
      await _loadChallenges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _uploadChallengesFromDataFile() async {
    setState(() => isLoading = true);
    try {
      for (var challenge in challengeData) {
        await FirebaseFirestore.instance
            .collection('challenges')
            .doc(challenge.id)
            .set(challenge.toMap());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Challenges uploaded from data file!")),
      );
      await _loadChallenges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _clearForm() {
    _selectedChallenge = null;
    nameController.clear();
    descController.clear();
    prizeAmountController.clear();
    instructionController.clear();
    instructions.clear();
    _selectedImage = null;
    _currentImageUrl = null;
    maxParticipantsController.clear();
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.grey[900],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  Widget _buildDynamicField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: instructionController,
          style: const TextStyle(color: Colors.white),
          decoration: _input("New Instruction"),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () {
            if (instructionController.text.isNotEmpty) {
              setState(() {
                instructions.add(instructionController.text.trim());
                instructionController.clear();
              });
            }
          },
          child: const Text("Add Instruction"),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              instructions.map((text) {
                return Chip(
                  label: Text(
                    text,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.grey[800],
                  onDeleted: () => setState(() => instructions.remove(text)),
                );
              }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Challenges"),
        backgroundColor: Colors.black,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Edit Existing Challenge",
                        style: TextStyle(color: Colors.white70),
                      ),
                      DropdownButtonFormField<Challenge>(
                        value: _selectedChallenge,
                        isExpanded: true,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        hint: const Text("Select or create a challenge"),
                        decoration: _input("Select Challenge"),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text("New Challenge"),
                          ),
                          ..._challenges.map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          ),
                        ],
                        onChanged: (val) => _onChallengeSelected(val),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _input("Challenge Name"),
                        validator:
                            (v) => v == null || v.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _input("Description"),
                      ),
                      const SizedBox(height: 12),

                      // Prize
                      TextFormField(
                        controller: prizeAmountController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _input("Prize Amount"),
                      ),
                      const SizedBox(height: 12),

                      // Max Participants
                      TextFormField(
                        controller: maxParticipantsController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _input("Max Participants (optional)"),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Challenge Image",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      _selectedImage != null
                          ? Image.file(File(_selectedImage!.path), height: 180)
                          : _currentImageUrl != null
                          ? Image.network(_currentImageUrl!, height: 180)
                          : Container(
                            height: 180,
                            color: Colors.grey[800],
                            child: IconButton(
                              icon: const Icon(
                                Icons.add_photo_alternate,
                                color: Colors.white,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                      const SizedBox(height: 16),

                      // Instructions dynamic field
                      _buildDynamicField(),
                      const SizedBox(height: 24),

                      // Save button
                      ElevatedButton(
                        onPressed: _saveChallenge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          _selectedChallenge != null
                              ? "Update Challenge"
                              : "Create Challenge",
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Delete button (only if we have a selected challenge)
                      if (_selectedChallenge != null)
                        ElevatedButton(
                          onPressed: _deleteChallenge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Delete Challenge"),
                        ),
                      const SizedBox(height: 12),

                      // Upload from data file
                      ElevatedButton(
                        onPressed: _uploadChallengesFromDataFile,
                        child: const Text("Upload Challenges from Data File"),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
