import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'Features/auth/presentation/view/auth_view.dart';

void main() {
  runApp(const SmartDoc());
}

class SmartDoc extends StatelessWidget {
  const SmartDoc({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Queue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ar'), // مؤقتًا خليها عربي، هنخليها dynamic بعدين
      home: const AuthScreen(),
    );
  }
}
