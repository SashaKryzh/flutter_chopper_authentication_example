import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:chopper_authenticator_example/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "chopper.chopper.dart";
part 'chopper.g.dart';

@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  return ApiService.create(ref);
}

@ChopperApi()
abstract class ApiService extends ChopperService {
  static ApiService create(ApiServiceRef ref) {
    final client = ChopperClient(
      client: mockClient(ref),
      authenticator: ref.read(myAuthenticatorProvider),
      interceptors: [
        ref.read(authInterceptorProvider),
      ],
      services: [
        _$ApiService(),
      ],
    );

    return _$ApiService(client);
  }

  static MockClient mockClient(ApiServiceRef ref) {
    return MockClient(
      (request) async {
        await Future.delayed(const Duration(seconds: 1));

        final serverAccessToken =
            ref.read(fakeRemoteServerProvider).accessToken;

        if (request.headers[HttpHeaders.authorizationHeader] !=
            serverAccessToken) {
          return http.Response(
            'Unauthorized',
            401,
          );
        }

        return http.Response(
          'Some fake data',
          200,
        );
      },
    );
  }

  @Get(path: '/data')
  Future<Response> getData();
}

//
// Auth interceptor
//

@riverpod
AuthInterceptor authInterceptor(AuthInterceptorRef ref) {
  return AuthInterceptor(ref);
}

class AuthInterceptor implements RequestInterceptor {
  const AuthInterceptor(this.ref);

  final AuthInterceptorRef ref;

  @override
  FutureOr<Request> onRequest(Request request) {
    print(
      '[AuthInterceptor] accessToken: ${ref.read(authRepositoryProvider).accessToken}',
    );

    return applyHeader(
      request,
      HttpHeaders.authorizationHeader,
      ref.read(authRepositoryProvider).accessToken,
      override: false,
    );
  }
}

//
// Authenticator
//

@riverpod
MyAuthenticator myAuthenticator(MyAuthenticatorRef ref) {
  return MyAuthenticator(ref);
}

class MyAuthenticator implements Authenticator {
  MyAuthenticator(this.ref);

  final MyAuthenticatorRef ref;

  @override
  FutureOr<Request?> authenticate(
    Request request,
    Response response, [
    Request? originalRequest,
  ]) async {
    print('[MyAuthenticator] response.statusCode: ${response.statusCode}');
    print(
      '[MyAuthenticator] request Retry-Count: ${request.headers['Retry-Count']}',
    );

    // 401
    if (response.statusCode == HttpStatus.unauthorized) {
      // Trying to update token only 1 time
      if (request.headers['Retry-Count'] != null) {
        print('[MyAuthenticator] Unable to refresh token, retry count exceeded');
        return null;
      }

      final newToken = await _refreshToken();

      return applyHeaders(
        request,
        {
          HttpHeaders.authorizationHeader: newToken,
          'Retry-Count': '1',
        },
      );
    }

    return null;
  }

  Completer<String>? _completer;

  Future<String> _refreshToken() {
    var completer = _completer;
    if (completer != null && !completer.isCompleted) {
      print('Token refresh is already in progress');
      return completer.future;
    }

    completer = Completer<String>();
    _completer = completer;

    ref.read(authRepositoryProvider).refreshToken().then((_) {
      final newToken = ref.read(authRepositoryProvider).accessToken;
      completer?.complete(newToken);
    });

    return completer.future;
  }
}
