
import 'package:document_search/screns/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
class ResponsiveSearchApp extends StatelessWidget {
  const ResponsiveSearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Search System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: const GoogleSearchPage(),
    );
  }
}