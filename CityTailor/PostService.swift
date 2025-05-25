import Foundation
import UIKit

class PostService {
    static let shared = PostService()
    private let baseURL = "https://alex.polan.sk/ct/backend/posts"
    private let imageBaseURL = "https://alex.polan.sk/ct/backend"
    
    private init() {}
    
    func fetchPosts() async throws -> [CommunityPost] {
        guard let url = URL(string: "\(baseURL)/posts.php") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data:", responseString)
        }
        
        let decoder = JSONDecoder()
        let posts = try decoder.decode([PostResponse].self, from: data)
        
        return posts.map { response in
            let date: Date
            if response.timestamp == "0000-00-00 00:00:00" {
                date = Date()
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                date = formatter.date(from: response.timestamp) ?? Date()
            }
            
            return CommunityPost(
                id: UUID(uuidString: response.id) ?? UUID(),
                username: response.username,
                userAvatar: "person.crop.circle.fill",
                location: response.location,
                caption: response.caption,
                images: [],
                imageNames: response.imageUrls,
                likes: 0,
                comments: 0,
                timestamp: date
            )
        }
    }
    
    func createPost(location: String, caption: String, images: [UIImage]) async throws {
        guard let url = URL(string: "\(baseURL)/posts.php") else {
            throw URLError(.badURL)
        }
        
        let imageStrings = try images.map { image in
            guard let imageData = image.jpegData(compressionQuality: 0.7) else {
                throw URLError(.cannotDecodeContentData)
            }
            return imageData.base64EncodedString()
        }
        
        let post = PostRequest(
            location: location,
            caption: caption,
            images: imageStrings,
            timestamp: Date()
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(post)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response Data:", responseString)
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    private func loadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
    
    func loadImagesForPost(_ post: CommunityPost) async throws -> CommunityPost {
        var loadedImages: [UIImage] = []
        
        for imagePath in post.imageNames {
            let fullImageUrl = imageBaseURL + imagePath
            let image = try await loadImage(from: fullImageUrl)
            loadedImages.append(image)
        }
        
        return CommunityPost(
            id: post.id,
            username: post.username,
            userAvatar: post.userAvatar,
            location: post.location,
            caption: post.caption,
            images: loadedImages,
            imageNames: post.imageNames,
            likes: post.likes,
            comments: post.comments,
            timestamp: post.timestamp
        )
    }
}

struct PostResponse: Codable {
    let id: String
    let username: String
    let location: String
    let caption: String
    let imageUrls: [String]
    let timestamp: String
    let images: [String]?
}

struct PostRequest: Codable {
    let location: String
    let caption: String
    let images: [String]
    let timestamp: Date
}