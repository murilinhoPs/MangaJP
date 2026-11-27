#include "FHashTable.hpp"
#include "json.hpp"
#include <cstring>
#include <exception>
#include <libsecret/secret.h>
#include <string>

#define secret_autofree _GLIB_CLEANUP(secret_cleanup_free)
static inline void secret_cleanup_free(gchar **p) { secret_password_free(*p); }

// Do not throw C++ exceptions from this file. `g_autoptr` / GLib nested
// main loops (the GNOME keyring dialog inside secret_password_storev_sync)
// are not exception-safe: `throw std::runtime_error` still ended the
// process with `terminate called after throwing an instance of
// 'std::runtime_error'` (GNOME Cancel). Return codes only.

class SecretStorage {
  FHashTable m_attributes;
  std::string label;
  SecretSchema the_schema;
  bool m_locked = false;
  std::string m_error;

public:
  const char *getLabel() { return label.c_str(); }
  void setLabel(const char *label) { this->label = label; }

  bool wasLocked() const { return m_locked; }
  const std::string &lastError() const { return m_error; }
  void clearStatus() {
    m_locked = false;
    m_error.clear();
  }

  SecretStorage(const char *_label = "default") : label(_label) {
    the_schema = {label.c_str(),
                  SECRET_SCHEMA_NONE,
                  {
                      {"account", SECRET_SCHEMA_ATTRIBUTE_STRING},
                  }};
  }

  void addAttribute(const char *key, const char *value) {
    m_attributes.insert(key, value);
  }

  bool addItem(const char *key, const char *value) {
    nlohmann::json root = readFromKeyring();
    if (m_locked || !m_error.empty()) {
      return false;
    }
    root[key] = value;
    return storeToKeyring(root);
  }

  std::string getItem(const char *key) {
    nlohmann::json root = readFromKeyring();
    if (m_locked || !m_error.empty()) {
      return "";
    }
    nlohmann::json value = root[key];
    if (value.is_string()) {
      return value.get<std::string>();
    }
    return "";
  }

  void deleteItem(const char *key) {
    nlohmann::json root = readFromKeyring();
    if (m_locked || !m_error.empty() || root.is_null()) {
      return;
    }
    root.erase(key);
    storeToKeyring(root);
  }

  bool deleteKeyring() { return this->storeToKeyring(nlohmann::json()); }

  bool storeToKeyring(nlohmann::json value) {
    const std::string output = value.dump(0);
    GError *err = nullptr;
    bool result = secret_password_storev_sync(
        &the_schema, m_attributes.getGHashTable(), nullptr, label.c_str(),
        output.c_str(), nullptr, &err);

    if (err) {
      setErrorFromGError(err);
      g_error_free(err);
      return false;
    }
    if (!result) {
      setLocked();
      return false;
    }
    return true;
  }

  nlohmann::json readFromKeyring() {
    nlohmann::json value;
    if (!warmupKeyring()) {
      return value;
    }

    GError *err = nullptr;
    secret_autofree gchar *result = secret_password_lookupv_sync(
        &the_schema, m_attributes.getGHashTable(), nullptr, &err);

    if (err) {
      setErrorFromGError(err);
      g_error_free(err);
      return value;
    }
    if (result != NULL && strcmp(result, "") != 0) {
      try {
        value = nlohmann::json::parse(result);
      } catch (const std::exception &e) {
        m_error = e.what();
      }
    }
    return value;
  }

private:
  void setLocked() {
    m_locked = true;
    m_error = "KeyringLocked";
  }

  void setErrorFromGError(GError *err) {
    const char *msg = (err && err->message) ? err->message : "Libsecret error";
    if (strstr(msg, "unlock") != nullptr || strstr(msg, "cancelled") != nullptr ||
        strstr(msg, "canceled") != nullptr) {
      setLocked();
      return;
    }
    m_error = msg;
  }

  // Search with schemas fails in cold keyrings.
  // https://gitlab.gnome.org/GNOME/gnome-keyring/-/issues/89
  //
  // Dummy store without `the_schema` (http://crbug.com/660005) so Cancel is
  // distinguishable from a missing item. Must not throw: GNOME Cancel used
  // to `throw "Failed to unlock the keyring"` (`char const*`) and then
  // `std::runtime_error`, both of which `std::terminate` the Flutter Linux
  // process.
  bool warmupKeyring() {
    clearStatus();
    GError *err = nullptr;

    FHashTable attributes;
    attributes.insert("explanation",
                      "Because of quirks in the gnome libsecret API, "
                      "flutter_secret_storage needs to store a dummy entry to "
                      "guarantee that this keyring was properly unlocked. More "
                      "details at http://crbug.com/660005.");

    const gchar *dummy_label = "FlutterSecureStorage Control";

    bool success = secret_password_storev_sync(
        NULL, attributes.getGHashTable(), nullptr, dummy_label,
        "The meaning of life", nullptr, &err);

    if (err) {
      setErrorFromGError(err);
      g_error_free(err);
      return false;
    }
    if (!success) {
      setLocked();
      return false;
    }
    return true;
  }
};
