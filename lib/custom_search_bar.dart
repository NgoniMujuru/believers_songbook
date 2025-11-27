import 'package:believers_songbook/providers/theme_settings.dart';
import 'package:provider/provider.dart';

import 'styles.dart';
import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    required this.controller,
    required this.focusNode,
    Key? key,
  }) : super(key: key);

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeSettings>(
        builder: (context, themeSettings, child) => DecoratedBox(
              decoration: BoxDecoration(
                color: themeSettings.isDarkMode
                    ? Styles.searchBackgroundDark
                    : Styles.searchBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: themeSettings.isDarkMode
                          ? Styles.searchIconColorDark
                          : Styles.searchIconColor,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: themeSettings.isDarkMode
                            ? Styles.searchTextDark
                            : Styles.searchText,
                        cursorColor: themeSettings.isDarkMode
                            ? Styles.searchCursorColorDark
                            : Styles.searchCursorColor,
                        decoration: null,
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.clear,
                      child: Icon(
                        Icons.clear,
                        color: themeSettings.isDarkMode
                            ? Styles.searchIconColorDark
                            : Styles.searchIconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }
}
