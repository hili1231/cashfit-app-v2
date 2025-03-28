import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/side_hustle.dart';
import '../../data/side_hustle_data.dart';

class AdminCreateSideHustleScreen extends StatefulWidget {
  const AdminCreateSideHustleScreen({super.key});

  @override
  State<AdminCreateSideHustleScreen> createState() =>
      _AdminCreateSideHustleScreenState();
}

class _AdminCreateSideHustleScreenState
    extends State<AdminCreateSideHustleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoRequirementController = TextEditingController();
  final _rewardController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _pickedImage;
  DateTime? _endDate;
  bool _isActive = true;
  String? _creatorId;
  String? selectedHustleId;
  List<SideHustle> allHustles = [];

  @override
  void initState() {
    super.initState();
    _loadSideHustles();
  }

  Future<void> _loadSideHustles() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('sideHustles').get();
    setState(() {
      allHustles =
          snapshot.docs.map((doc) => SideHustle.fromMap(doc.data())).toList();
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  void _populateFields(SideHustle hustle) {
    _titleController.text = hustle.title;
    _descriptionController.text = hustle.description;
    _rewardController.text = hustle.reward.toString();
    _videoRequirementController.text = hustle.videoRequirement;
    _tagsController.text = hustle.tags.join(", ");
    _maxParticipantsController.text = hustle.maxParticipants?.toString() ?? '';
    _endDate = hustle.endDate;
    _isActive = hustle.isActive;
    _creatorId = hustle.creatorId;
  }

  Future<void> _saveSideHustle() async {
    if (!_formKey.currentState!.validate()) return;

    final id = selectedHustleId ?? "hustle_${Random().nextInt(999999)}";

    final hustle = SideHustle(
      id: id,
      title: _titleController.text,
      description: _descriptionController.text,
      reward: int.tryParse(_rewardController.text) ?? 0,
      videoRequirement: _videoRequirementController.text,
      thumbnail: _pickedImage?.path ?? '',
      endDate: _endDate,
      isActive: _isActive,
      creatorId: _creatorId,
      tags:
          _tagsController.text
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList(),
      maxParticipants: int.tryParse(_maxParticipantsController.text),
    );

    await FirebaseFirestore.instance
        .collection('sideHustles')
        .doc(hustle.id)
        .set(hustle.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(selectedHustleId != null ? "✅ Updated!" : "✅ Created!"),
      ),
    );

    if (selectedHustleId == null) {
      Navigator.pop(context);
    }
  }

  Future<void> _uploadSampleSideHustles() async {
    for (final hustle in sideHustleData) {
      await FirebaseFirestore.instance
          .collection('sideHustles')
          .add(hustle.toMap());
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Sample side hustles uploaded")),
    );
    _loadSideHustles();
  }

  InputDecoration _input(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.grey[850],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Manage Side Hustles"),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedHustleId,
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: _input("Select to Edit (optional)"),
                items:
                    allHustles
                        .map(
                          (h) => DropdownMenuItem(
                            value: h.id,
                            child: Text(
                              h.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (id) {
                  final selected = allHustles.firstWhere((h) => h.id == id);
                  setState(() {
                    selectedHustleId = id;
                    _populateFields(selected);
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _input("Title"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _input("Description"),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _videoRequirementController,
                style: const TextStyle(color: Colors.white),
                decoration: _input("Video Requirement"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rewardController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _input("Reward (points)"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: _input("Tags (comma separated)"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxParticipantsController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _input("Max Participants (optional)"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text("Active?", style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _isActive,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _endDate != null
                      ? "End Date: ${_endDate!.toLocal().toString().split(' ')[0]}"
                      : "Pick End Date",
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _endDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text("Pick Thumbnail"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                ),
              ),
              if (_pickedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Image.file(File(_pickedImage!.path), height: 150),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSideHustle,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  selectedHustleId == null
                      ? "Create Side Hustle"
                      : "Update Side Hustle",
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _uploadSampleSideHustles,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Sample Side Hustles"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
