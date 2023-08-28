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
              // Button to emulate network request
              ElevatedButton(
                onPressed: () async {
                  final result = await ref.read(apiServiceProvider).getData();
                  print(result.bodyString);
                },
                child: const Text('Get data'),
              ),
              // Button to emulate token invalidation on remote server
              OutlinedButton(
                onPressed: () {
                  ref.read(fakeRemoteServerProvider).invalidateToken();
                },
                child: const Text('Invalidate token on remote server'),
              ),
              const SizedBox(height: 16),
              // Button to set if the remote server will or will not return a new valid token
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
              // Button to set if the auth repository will or will not throw an exception on refresh
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Is to throw Exception on refresh: '),
                  ValueListenableBuilder(
                    valueListenable: isToThrowExceptionOnRefresh,
                    builder: (context, value, _) => Switch(
                      value: value,
                      onChanged: (value) {
                        isToThrowExceptionOnRefresh.value = value;
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
