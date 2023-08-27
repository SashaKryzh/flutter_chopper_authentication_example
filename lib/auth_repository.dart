import 'dart:math';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(fakeRemoteServerProvider));
}

class AuthRepository {
  AuthRepository(this._fakeRemoteServer);

  final FakeRemoteServer _fakeRemoteServer;

  var _accessToken = 'initial-valid-token';
  String get accessToken => _accessToken;

  Future<void> refreshToken() async {
    _accessToken = await _fakeRemoteServer.getNewToken();
  }
}

//
// Fake remote server
//

final isAbleToRefreshToken = ValueNotifier(true);

@Riverpod(keepAlive: true)
FakeRemoteServer fakeRemoteServer(FakeRemoteServerRef ref) {
  return FakeRemoteServer();
}

class FakeRemoteServer {
  var _accessToken = 'initial-valid-token';
  String get accessToken => _accessToken;

  Future<String> getNewToken() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!isAbleToRefreshToken.value) {
      return 'unable-to-get-new-token';
    }
    return _accessToken;
  }

  void invalidateToken() async {
    _accessToken = Random().nextInt(1000).toString();
  }
}
