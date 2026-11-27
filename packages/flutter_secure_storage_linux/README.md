# flutter_secure_storage_linux (MangaJP patch)

Vendored from `flutter_secure_storage_linux` **1.2.3** (upstream of
`flutter_secure_storage` 9.2.4).

## Why this copy exists

Canceling the GNOME keyring dialog in Ajustes killed the Linux app:

```
terminate called after throwing 'char const*'
```

Root cause (native, not catchable in Dart):

1. `warmupKeyring()` in `Secret.hpp` does `throw "Failed to unlock the keyring"`
   when `secret_password_storev_sync` returns false (user Cancel). That is a
   C string (`char const*`). The plugin handler only `catch (const gchar *e)`;
   on Flutter Linux that throw still reaches `std::terminate`.
2. `throw err->message` is a use-after-free: `g_autoptr(GError)` frees the
   GError while the exception unwinds, then the handler reads the dangling
   pointer.

Dart `try/catch` never runs. The process is already dead.

## Patch

- Copy GError messages into `std::runtime_error` before unwind.
- Map Cancel / failed unlock to `std::runtime_error("KeyringLocked")`.
- Catch `std::exception`, leftover C strings, and `...` and return a
  `PlatformException` (`KeyringLocked` or `Libsecret error`) on the method
  channel.

The app maps that to a PT-BR «tente de novo» state instead of crashing.

Do not bump this override to `flutter_secure_storage_linux` 3.x without a
`flutter_secure_storage` 10+ upgrade — 9.2.4 expects the 1.x plugin.
