import 'package:chopper_authenticator_example/auth_repository.dart';
import 'package:chopper_authenticator_example/chopper.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(apiServiceProvider).getData();
                },
                child: const Text('Get data'),
              ),
              OutlinedButton(
                onPressed: () {
                  ref.read(fakeRemoteServerProvider).invalidateToken();
                },
                child: const Text('Invalidate token on remote server'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Is able to refresh token: '),
                  ValueListenableBuilder(
                    valueListenable: isAbleToRefreshToken,
                    builder: (context, value, _) => Switch(
                      value: value,
                      onChanged: (value) {
                        isAbleToRefreshToken.value = value;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
