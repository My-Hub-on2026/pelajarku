import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_shell.dart';
import 'state/app_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final AppStore store = AppStore();
  await store.initialize();
  runApp(PelajarKuApp(store: store));
}

class PelajarKuApp extends StatelessWidget {
  const PelajarKuApp({required this.store, super.key});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PelajarKu',
        locale: const Locale('id', 'ID'),
        supportedLocales: const <Locale>[
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        home: const HomeShell(),
      ),
    );
  }
}
