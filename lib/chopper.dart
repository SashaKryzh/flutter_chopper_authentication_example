import 'dart:async';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:chopper_authenticator_example/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chopper.chopper.dart';
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
      // Authenticator
      authenticator: ref.read(myAuthenticatorProvider),
      interceptors: [
        // AuthInterceptor
        ref.read(authInterceptorProvider),
      ],
      services: [
        _$ApiService(),
      ],
    );

    return _$ApiService(client);
  }

  static MockClient mockClient(ApiServiceRef ref) {
    // Returns data if the token is valid or 401 otherwise
    return MockClient(
      (request) async {
        await Future.delayed(const Duration(seconds: 1));

        // Get currently valid token from remote server
        final serverAccessToken =
            ref.read(fakeRemoteServerProvider).accessToken;

        // 1. If accessToken in the request doesn't match the token on the remote server,
        //    then return 401
        if (request.headers[HttpHeaders.authorizationHeader] !=
            serverAccessToken) {
          return http.Response(
            'Unauthorized',
            401,
          );
        }

        // 2. If tokens are equal, then return some fake data
        return http.Response(
          'Success',
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
  return AuthInterceptor(ref.watch(authRepositoryProvider));
}

class AuthInterceptor implements RequestInterceptor {
  const AuthInterceptor(this._repo);

  final AuthRepository _repo;

  @override
  FutureOr<Request> onRequest(Request request) {
    final updatedRequest = applyHeader(
      request,
      HttpHeaders.authorizationHeader,
      _repo.accessToken,
      // Do not override existing header
      override: false,
    );

    print(
      '[AuthInterceptor] accessToken: ${updatedRequest.headers[HttpHeaders.authorizationHeader]}',
    );

    return updatedRequest;
  }
}

//
// Authenticator
//

@riverpod
MyAuthenticator myAuthenticator(MyAuthenticatorRef ref) {
  return MyAuthenticator(ref.watch(authRepositoryProvider));
}

class MyAuthenticator implements Authenticator {
  MyAuthenticator(this._repo);

  final AuthRepository _repo;

  @override
  FutureOr<Request?> authenticate(
    Request request,
    Response response, [
    Request? originalRequest,
  ]) async {
    print('[MyAuthenticator] response.statusCode: ${response.statusCode}');
    print(
      '[MyAuthenticator] request Retry-Count: ${request.headers['Retry-Count'] ?? 0}',
    );

    // 401
    if (response.statusCode == HttpStatus.unauthorized) {
      // Trying to update token only 1 time
      if (request.headers['Retry-Count'] != null) {
        print(
          '[MyAuthenticator] Unable to refresh token, retry count exceeded',
        );
        return null;
      }

      try {
        final newToken = await _refreshToken();

        return applyHeaders(
          request,
          {
            HttpHeaders.authorizationHeader: newToken,
            // Setting the retry count to not end up in an infinite loop of unsuccessful updates
            'Retry-Count': '1',
          },
        );
      } catch (e) {
        print('[MyAuthenticator] Unable to refresh token: $e');
        return null;
      }
    }

    return null;
  }

  // Completer to prevent multiple token refreshes at the same time
  Completer<String>? _completer;

  Future<String> _refreshToken() {
    var completer = _completer;
    if (completer != null && !completer.isCompleted) {
      print('Token refresh is already in progress');
      return completer.future;
    }

    completer = Completer<String>();
    _completer = completer;

    _repo.refreshToken().then((_) {
      // Completing with a new token
      completer?.complete(_repo.accessToken);
    }).onError((error, stackTrace) {
      // Completing with an error
      completer?.completeError(error ?? 'Refresh token error', stackTrace);
    });

    return completer.future;
  }
}
