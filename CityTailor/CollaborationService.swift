import Foundation

class CollaborationService {
    static let shared = CollaborationService()
    private let baseURL = "https://alex.polan.sk/ct/backend/plans"
    
    private init() {}
    
    // MARK: - Access Code Management
    
    /// Generate an access code for a plan
    func generateAccessCode(for planId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plans.php?id=\(planId)&generate_access_code=true") else {
            completion(.failure(CollaborationError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(CollaborationError.noData))
                }
                return
            }
            
            do {
                let response = try JSONDecoder().decode(AccessCodeResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.access_code))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    /// Remove access code for a plan
    func removeAccessCode(for planId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plans.php?id=\(planId)&remove_access_code=true") else {
            completion(.failure(CollaborationError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }.resume()
    }
    
    /// Access a plan using an access code
    func accessPlanWithCode(_ accessCode: String, completion: @escaping (Result<TravelPlan, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/plans.php?access_code=\(accessCode)") else {
            completion(.failure(CollaborationError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(CollaborationError.noData))
                }
                return
            }
            
            do {
                let plan = try JSONDecoder().decode(TravelPlan.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(plan))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// MARK: - Response Models

struct AccessCodeResponse: Codable {
    let message: String
    let access_code: String
}

struct GeneralResponse: Codable {
    let message: String
}

// MARK: - Errors

enum CollaborationError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidAccessCode
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidAccessCode:
            return "Invalid access code"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
