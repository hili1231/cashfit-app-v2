import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ingredient.dart';
import '../../data/mock_ingredients.dart';

class AdminUploadIngredientsScreen extends StatefulWidget {
  const AdminUploadIngredientsScreen({super.key});

  @override
  State<AdminUploadIngredientsScreen> createState() =>
      _AdminUploadIngredientsScreenState();
}

class _AdminUploadIngredientsScreenState
    extends State<AdminUploadIngredientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Ingredient> parsedIngredients = [];
  bool isLoading = false;
  bool isSearching = false;

  Future<void> _searchAndFetchIngredients(String query) async {
    setState(() {
      isSearching = true;
      parsedIngredients = [];
    });

    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1',
      );

      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception("Failed to fetch data. Status code: ${response.statusCode}");
      }

      final data = json.decode(response.body);
      final List products = data['products'] ?? [];

      final List<Ingredient> fetched =
          products
              .map((product) {
                if ((product['product_name'] ?? '').toString().isEmpty) {
                  return null;
                }
                return Ingredient(
                  id: (product['product_name'] ?? 'unknown')
                      .toString()
                      .toLowerCase()
                      .replaceAll(RegExp(r'\s+'), '_')
                      .replaceAll(RegExp(r'[^a-z0-9_]+'), ''),
                  name: product['product_name'] ?? 'Unknown',
                  calories:
                      (product['nutriments']?['energy-kcal_100g'] ?? 0)
                          .toDouble(),
                  protein:
                      (product['nutriments']?['proteins_100g'] ?? 0).toDouble(),
                  carbs:
                      (product['nutriments']?['carbohydrates_100g'] ?? 0)
                          .toDouble(),
                  fat: (product['nutriments']?['fat_100g'] ?? 0).toDouble(),
                  fiber: (product['nutriments']?['fiber_100g'] ?? 0).toDouble(),
                  sugar:
                      (product['nutriments']?['sugars_100g'] ?? 0).toDouble(),
                  saturatedFat:
                      (product['nutriments']?['saturated-fat_100g'] ?? 0)
                          .toDouble(),
                  vitaminA:
                      (product['nutriments']?['vitamin-a_100g'] ?? 0)
                          .toDouble(),
                  vitaminC:
                      (product['nutriments']?['vitamin-c_100g'] ?? 0)
                          .toDouble(),
                  vitaminD:
                      (product['nutriments']?['vitamin-d_100g'] ?? 0)
                          .toDouble(),
                  vitaminK:
                      (product['nutriments']?['vitamin-k_100g'] ?? 0)
                          .toDouble(),
                  vitaminB12:
                      (product['nutriments']?['vitamin-b12_100g'] ?? 0)
                          .toDouble(),
                  iron: (product['nutriments']?['iron_100g'] ?? 0).toDouble(),
                  calcium:
                      (product['nutriments']?['calcium_100g'] ?? 0).toDouble(),
                  potassium:
                      (product['nutriments']?['potassium_100g'] ?? 0)
                          .toDouble(),
                  magnesium:
                      (product['nutriments']?['magnesium_100g'] ?? 0)
                          .toDouble(),
                  sodium:
                      (product['nutriments']?['sodium_100g'] ?? 0).toDouble(),
                  zinc: (product['nutriments']?['zinc_100g'] ?? 0).toDouble(),
                  cholesterol:
                      (product['nutriments']?['cholesterol_100g'] ?? 0)
                          .toDouble(),
                  glycemicIndex: null,
                );
              })
              .whereType<Ingredient>()
              .toList();

      fetched.sort(
        (a, b) => _stringSimilarity(
          query,
          b.name,
        ).compareTo(_stringSimilarity(query, a.name)),
      );

      setState(() => parsedIngredients = fetched);
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint("Search error: $e\n$stackTrace");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Search error: $e")));
    } finally {
      setState(() => isSearching = false);
    }
  }

  int _stringSimilarity(String a, String b) {
    a = a.toLowerCase();
    b = b.toLowerCase();

    if (a == b) return 100;
    if (b.contains(a)) return 75;
    if (a.contains(b)) return 75;

    int matches = 0;
    for (int i = 0; i < a.length && i < b.length; i++) {
      if (a[i] == b[i]) matches++;
    }
    return matches;
  }

  Future<void> uploadIngredients() async {
    setState(() => isLoading = true);
    try {
      final batchSize = 500;
      for (int i = 0; i < parsedIngredients.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = parsedIngredients.skip(i).take(batchSize);
        for (var ingredient in chunk) {
          final docRef = FirebaseFirestore.instance
              .collection('ingredients')
              .doc(ingredient.id);
          batch.set(docRef, ingredient.toMap());
        }
        await batch.commit();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ All ingredients uploaded!")),
      );
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint("Upload failed: $e\n$stackTrace");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> uploadSingleIngredient(Ingredient ingredient) async {
    try {
      await FirebaseFirestore.instance
          .collection('ingredients')
          .doc(ingredient.id)
          .set(ingredient.toMap()); // Changed to toMap()
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ '${ingredient.name}' uploaded.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  Future<void> _confirmAndUploadIngredients() async {
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Upload"),
        content: const Text("Are you sure you want to upload all ingredients?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Upload"),
          ),
        ],
      ),
    );

    if (shouldUpload == true) {
      await uploadIngredients();
    }
  }

  void _loadMockIngredients() {
    setState(() => parsedIngredients = mockIngredients);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("✅ Loaded mock ingredients!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Admin: Upload Ingredients"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search food (e.g. Chicken breast)",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      isSearching
                          ? null
                          : () => _searchAndFetchIngredients(
                            _searchController.text,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child:
                      isSearching
                          ? const CircularProgressIndicator()
                          : const Text("Search"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  parsedIngredients.isEmpty
                      ? const Center(
                        child: Text(
                          "🔍 Search or load mock ingredients",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                      : ListView.builder(
                        itemCount: parsedIngredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = parsedIngredients[index];
                          return Card(
                            color: Colors.grey[850],
                            child: ListTile(
                              title: Text(
                                ingredient.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                "${ingredient.calories.toStringAsFixed(0)} kcal, Protein: ${ingredient.protein}g",
                                style: const TextStyle(color: Colors.white60),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.cloud_upload,
                                  color: Colors.greenAccent,
                                ),
                                onPressed:
                                    () => uploadSingleIngredient(ingredient),
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed:
                      parsedIngredients.isNotEmpty && !isLoading
                          ? _confirmAndUploadIngredients
                          : null,
                  child:
                      isLoading
                          ? const CircularProgressIndicator()
                          : const Text("Upload All"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _loadMockIngredients,
                  child: const Text("Load Mock Data"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (parsedIngredients.isNotEmpty)
              Text(
                "✅ Parsed ${parsedIngredients.length} ingredient(s)",
                style: const TextStyle(color: Colors.greenAccent),
              ),
          ],
        ),
      ),
    );
  }
}
