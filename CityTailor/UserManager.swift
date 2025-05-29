import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    private enum Keys {
        static let username = "username"
        static let email = "email"
        static let isLoggedIn = "isLoggedIn"
    }
    
    @Published var currentUsername: String? {
        didSet {
            if let username = currentUsername {
                UserDefaults.standard.set(username, forKey: Keys.username)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.username)
            }
        }
    }
    
    @Published var currentEmail: String? {
        didSet {
            if let email = currentEmail {
                UserDefaults.standard.set(email, forKey: Keys.email)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.email)
            }
        }
    }
    
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: Keys.isLoggedIn)
        }
    }
    
    private init() {
        self.currentUsername = UserDefaults.standard.string(forKey: Keys.username)
        self.currentEmail = UserDefaults.standard.string(forKey: Keys.email)
        self.isLoggedIn = UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
    }
    
    func login(username: String, email: String) {
        self.currentUsername = username
        self.currentEmail = email
        self.isLoggedIn = true
    }
    
    func logout() {
        self.currentUsername = nil
        self.currentEmail = nil
        self.isLoggedIn = false
    }
}