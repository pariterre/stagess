import 'package:flutter/material.dart';

class Search extends StatefulWidget implements PreferredSizeWidget {
  const Search({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  State<Search> createState() => _SearchState();

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

class _SearchState extends State<Search> {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    // Force acquisition of focus for the search field when the widget is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 0,
        child: ListTile(
          leading: const Icon(Icons.search),
          title: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            decoration: const InputDecoration(
              hintText: 'Rechercher',
              border: InputBorder.none,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => widget.controller.text = '',
          ),
        ),
      ),
    );
  }
}
