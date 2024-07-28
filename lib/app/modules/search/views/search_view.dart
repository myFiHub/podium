import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/search_controller.dart' as SearchController;

class SearchView extends GetView<SearchController.SearchController> {
  const SearchView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          'Search View',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
