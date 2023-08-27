# Flutter Chopper authentication example with retry on 401 (Unauthorized)

The title speaks for itself.

**⭐️ Article on Medium** (TODO: add link)

## Structure

- [main.dart](lib/main.dart) - basic UI.
- [chopper.dart](lib/chopper.dart) - Chopper client, auth header interceptor, and Authenticator for retry on 401 (Unauthorized).
- [auth_repository.dart](lib/auth_repository.dart) - repository with an access token and fake remote server to emulate the access token invalidation.

---

Flutter version: 3.13.0
