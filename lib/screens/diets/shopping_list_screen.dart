import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/shopping_list_provider.dart';
import '../../utils/quantity_formatter.dart';
import '../../theme.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: "1");
    final unitCtrl = TextEditingController(text: "pcs");
    String category = "Pantry";

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add Custom Item"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Item Name"),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: "Quantity"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(labelText: "Unit"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ["Produce", "Meat & Seafood", "Dairy", "Pantry", "Beverages"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                  context.read<ShoppingListProvider>().addItem(
                        nameCtrl.text.trim(),
                        qty,
                        unitCtrl.text.trim(),
                        category,
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final provider = Provider.of<ShoppingListProvider>(context);

    // Group items by category
    final Map<String, List<ShoppingItem>> grouped = {};
    for (var item in provider.items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      decoration: AppTheme.backgroundGradient(colorScheme),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("GROCERY SHOPPING LIST"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (provider.completedItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: "Clear Completed",
                onPressed: () => provider.clearCompleted(),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(context),
          icon: const Icon(Icons.add),
          label: const Text("Add Item"),
        ),
        body: provider.items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Your Shopping List is empty",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add items manually or export directly from Meal Plans",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: grouped.entries.map((entry) {
                  return Card(
                    color: colorScheme.surfaceContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.toUpperCase(),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          ...entry.value.map((item) {
                            return CheckboxListTile(
                              value: item.isDone,
                              activeColor: colorScheme.primary,
                              title: Text(
                                item.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: item.isDone
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                "${QuantityFormatter.format(item.quantity)} ${item.unit}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              secondary: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => provider.removeItem(item.id),
                              ),
                              onChanged: (val) {
                                provider.toggleItem(item.id);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
