import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';

import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  // late Future<List<GroceryItem>> _loadedItems;

  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // _loadedItems = _loadItems();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      "demoone-587a4-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        // throw Exception("Failed to fetch grocery items. please try again!!");
        setState(() {
          _error = "Failed to fetch data";
        });
      }

      if (response.body == "null") {
        setState(() {
          _isLoading = false;
        });
        // return [];
      }

      final Map<String, dynamic> listData = json.decode(response.body);

      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category =
            categories.entries
                .firstWhere(
                  (catItem) => catItem.value.title == item.value["category"],
                )
                .value;

        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value["name"],
            quantity: item.value["quantity"],
            category: category,
          ),
        );
      }
      // return loadedItems;
      setState(() {
        _groceryItems = loadedItems;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = "Something went wrong!!";
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(
      context,
    ).push<GroceryItem>(MaterialPageRoute(builder: (ctx) => NewItem()));

    // _loadItems();

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https(
      "demoone-587a4-default-rtdb.firebaseio.com",
      "shopping-list/${item.id}.json",
    );

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      // optional show error message
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(child: Text("No Data"));

    if (_isLoading) {
      content = Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemBuilder:
            (ctx, index) => Dismissible(
              onDismissed: (direction) => _removeItem(_groceryItems[index]),
              key: ValueKey(_groceryItems[index].id),
              child: ListTile(
                title: Text(_groceryItems[index].name),
                leading: Container(
                  width: 24,
                  height: 24,
                  color: _groceryItems[index].category.color,
                ),
                trailing: Text(_groceryItems[index].quantity.toString()),
              ),
            ),
        itemCount: _groceryItems.length,
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Your Groceries"),
        actions: [IconButton(onPressed: _addItem, icon: Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
