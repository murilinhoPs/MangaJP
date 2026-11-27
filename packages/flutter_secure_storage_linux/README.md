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

- **Do not throw.** `g_autoptr` + the nested GLib loop inside
  `secret_password_storev_sync` are not exception-safe. `throw char const*`
  *and* `throw std::runtime_error` both `std::terminate` the Flutter Linux
  process on GNOME Cancel (verified on this VM).
- Map Cancel / failed unlock to `SecretStorage::wasLocked()` and return
  `PlatformException(code: KeyringLocked)` on the method channel.
- Catch leftover C++ exceptions only as a last resort in the GObject
  method-call callback.

The app maps that to a PT-BR «tente de novo» state instead of crashing.

Do not bump this override to `flutter_secure_storage_linux` 3.x without a
`flutter_secure_storage` 10+ upgrade — 9.2.4 expects the 1.x plugin.
