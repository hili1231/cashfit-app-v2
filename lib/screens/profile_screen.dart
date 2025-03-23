import 'package:flutter/material.dart';
import '../data/user_data.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    controllers['name'] = TextEditingController(text: currentUser?.name ?? '');
    controllers['email'] = TextEditingController(
      text: currentUser?.email ?? '',
    );
    controllers['gender'] = TextEditingController(
      text: currentUser?.gender ?? '',
    );
    controllers['age'] = TextEditingController(text: currentUser?.age ?? '');
    controllers['height'] = TextEditingController(
      text: currentUser?.height ?? '',
    );
    controllers['weight'] = TextEditingController(
      text: currentUser?.weight ?? '',
    );
    controllers['activityLevel'] = TextEditingController(
      text: currentUser?.activityLevel ?? '',
    );
    controllers['dietGoal'] = TextEditingController(
      text: currentUser?.dietGoal ?? '',
    );
    controllers['dietPreference'] = TextEditingController(
      text: currentUser?.dietPreference ?? '',
    );
    controllers['workoutGoal'] = TextEditingController(
      text: currentUser?.workoutGoal ?? '',
    );
    controllers['experienceLevel'] = TextEditingController(
      text: currentUser?.experienceLevel ?? '',
    );
    controllers['trainingStyle'] = TextEditingController(
      text: currentUser?.trainingStyle ?? '',
    );
    controllers['workoutFrequency'] = TextEditingController(
      text: currentUser?.workoutFrequency?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateUser(String key, String value) {
    setState(() {
      switch (key) {
        case 'name':
          currentUser?.name = value;
          break;
        case 'email':
          currentUser?.email = value;
          break;
        case 'gender':
          currentUser?.gender = value;
          break;
        case 'age':
          currentUser?.age = value;
          break;
        case 'height':
          currentUser?.height = value;
          break;
        case 'weight':
          currentUser?.weight = value;
          break;
        case 'activityLevel':
          currentUser?.activityLevel = value;
          break;
        case 'dietGoal':
          currentUser?.dietGoal = value;
          break;
        case 'dietPreference':
          currentUser?.dietPreference = value;
          break;
        case 'workoutGoal':
          currentUser?.workoutGoal = value;
          break;
        case 'experienceLevel':
          currentUser?.experienceLevel = value;
          break;
        case 'trainingStyle':
          currentUser?.trainingStyle = value;
          break;
        case 'workoutFrequency':
          currentUser?.workoutFrequency = int.tryParse(value);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.amber,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(
                            currentUser?.avatar ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...controllers.entries
                          .map(
                            (entry) =>
                                _buildEditableField(entry.key, entry.value),
                          )
                          ,
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox(
                              "Workouts",
                              (currentUser?.workoutsCompleted ?? 0).toString(),
                            ),
                            _buildStatBox(
                              "Meals",
                              (currentUser?.mealsTracked ?? 0).toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildListTile(
                        icon: Icons.settings,
                        title: "Settings",
                        color: Colors.white70,
                        onTap: () {},
                      ),
                      _buildListTile(
                        icon: Icons.logout,
                        title: "Logout",
                        color: Colors.red,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black87,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String key, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: (value) => _updateUser(key, value),
        style: const TextStyle(color: Colors.white70),
        decoration: InputDecoration(
          labelText: _labelFromKey(key),
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.grey[850],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.amber),
          ),
        ),
      ),
    );
  }

  String _labelFromKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .replaceFirst(key[0], key[0].toUpperCase());
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.amber,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}
