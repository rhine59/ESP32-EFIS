import Foundation
import Security

struct KeychainStore {
    private let service = "uk.co.thingies.efisservice.licence"
    private let account = "cached-signed-envelope"

    func save(_ summary: LicenceSummary) throws {
        let data = try JSONEncoder().encode(summary)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else { throw LicenceAppError.service("Could not store the signed licence securely (\(status)).") }
    }

    func load() -> LicenceSummary? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(LicenceSummary.self, from: data)
    }

    func clear() {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as CFDictionary)
    }
}

struct AccountSession: Codable { let userID: Int; let email: String; let token: String; let expiresAt: Date }

extension KeychainStore {
    func saveAccount(_ session: AccountSession) throws {
        let data = try JSONEncoder().encode(session)
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "lollipop-account"]
        SecItemDelete(q as CFDictionary); var a=q; a[kSecValueData as String]=data; a[kSecAttrAccessible as String]=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(a as CFDictionary,nil) == errSecSuccess else { throw LicenceAppError.service("Could not securely save Lollipop account.") }
    }
    func clearAccount() {
        SecItemDelete([kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"lollipop-account"] as CFDictionary)
    }
    func loadAccount() -> AccountSession? {
        let q: [String: Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"lollipop-account",kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]; var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary,&item)==errSecSuccess, let data=item as? Data else{return nil}; return try? JSONDecoder().decode(AccountSession.self,from:data)
    }
}
