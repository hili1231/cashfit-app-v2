// Full file with all UI fixes and proper dropdown handling
// File: admin_upload_challenges_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final participantsController = TextEditingController();
  final prizeAmountController = TextEditingController();

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
    setState(() => isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('challenges').get();
      final List<Challenge> loaded =
          snapshot.docs.map((doc) => Challenge.fromMap(doc.data())).toList();
      setState(() => _challenges = loaded);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load challenges: $e")));
    }
    setState(() => isLoading = false);
  }

  void _onChallengeSelected(Challenge? challenge) {
    setState(() {
      _selectedChallenge = challenge;
      if (challenge != null) {
        nameController.text = challenge.name;
        descController.text = challenge.description;
        participantsController.text = challenge.participants.toString();
        prizeAmountController.text = challenge.prizeAmount.toString();
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

    final String challengeId =
        _selectedChallenge?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
        setState(() => isLoading = false);
        return;
      }
    }

    final updated = Challenge(
      id: challengeId,
      name: nameController.text,
      description: descController.text,
      image: imageUrl,
      participants: int.tryParse(participantsController.text) ?? 0,
      prizeAmount: double.tryParse(prizeAmountController.text) ?? 0.0,
      instructions: instructions,
      progressVideos: _selectedChallenge?.progressVideos ?? {},
    );

    try {
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(challengeId)
          .set(updated.toMap());
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
      _loadChallenges();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }
    setState(() => isLoading = false);
  }

  Future<void> _deleteChallenge() async {
    if (_selectedChallenge == null) return;
    setState(() => isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('challenges')
          .doc(_selectedChallenge!.id)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Challenge deleted!")));
      _clearForm();
      _loadChallenges();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
    setState(() => isLoading = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Challenges uploaded from data file!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
    setState(() => isLoading = false);
  }

  void _clearForm() {
    _selectedChallenge = null;
    nameController.clear();
    descController.clear();
    participantsController.clear();
    prizeAmountController.clear();
    instructionController.clear();
    instructions.clear();
    _selectedImage = null;
    _currentImageUrl = null;
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
              instructions
                  .map(
                    (text) => Chip(
                      label: Text(
                        text,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.grey[800],
                      onDeleted:
                          () => setState(() => instructions.remove(text)),
                    ),
                  )
                  .toList(),
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
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _input("Challenge Name"),
                        validator:
                            (v) => v == null || v.isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _input("Description"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: participantsController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _input("Participants"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: prizeAmountController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _input("Prize Amount"),
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
                      _buildDynamicField(),
                      const SizedBox(height: 24),
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
                      if (_selectedChallenge != null)
                        ElevatedButton(
                          onPressed: _deleteChallenge,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Delete Challenge"),
                        ),
                      const SizedBox(height: 12),
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
