import SwiftUI

struct MediaView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @StateObject private var viewModel: MediaViewModel
    @State private var showingImagePicker = false
    @State private var showingCreatePost = false
    @State private var isLoading = false
    
    init() {
        let languageManager = LanguageManager()
        _viewModel = StateObject(wrappedValue: MediaViewModel(languageManager: languageManager))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        PostCard(post: post)
                            .task {
                                if post.images.isEmpty {
                                    await viewModel.loadImagesForPost(post)
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle(viewModel.languageManager.localize("community_feed"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreatePost = true }) {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.fetchPosts()
        }
        .task {
            await viewModel.fetchPosts()
        }
        .sheet(isPresented: $showingCreatePost) {
            AddPostView(onPostAdded: { post in
                Task {
                    await viewModel.fetchPosts()
                }
            })
        }
    }
}

class MediaViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    let postService = PostService.shared
    let languageManager: LanguageManager
    
    init(languageManager: LanguageManager) {
        self.languageManager = languageManager
    }
    
    @MainActor
    func fetchPosts() async {
        do {
            posts = try await postService.fetchPosts()
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
    
    @MainActor
    func loadImagesForPost(_ post: CommunityPost) async {
        do {
            if let index = posts.firstIndex(where: { $0.id == post.id }) {
                posts[index] = try await postService.loadImagesForPost(post)
            }
        } catch {
            print("Error loading images for post: \(error)")
        }
    }
}

struct PostCard: View {
    let post: CommunityPost
    @State private var isLiked = false
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            HStack {
                Image(systemName: post.userAvatar)
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text(post.username)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                        
                        Text(post.location)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(timeAgo(post.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            
            if !post.imageNames.isEmpty {
                let imageUrl = "https://alex.polan.sk/ct/backend\(post.imageNames[0])"
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 300)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if !post.imageNames.isEmpty, let firstImage = post.imageNames.first {
                if let image = UIImage(named: firstImage) {
                    AsyncImage(url: URL(string: "data:image/png;base64,\(image.pngData()?.base64EncodedString() ?? "")")) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 300)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                                .overlay(
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
            }
            
            Text(post.caption)
                .padding(.horizontal)
            
            HStack {
                Button(action: {
                    isLiked.toggle()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        
                        Text("\(post.likes + (isLiked ? 1 : 0))")
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                    
                    Text("\(post.comments)")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.top, 8)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private func timeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day) \(day == 1 ? languageManager.localize("day_ago") : languageManager.localize("days_ago"))"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour) \(hour == 1 ? languageManager.localize("hour_ago") : languageManager.localize("hours_ago"))"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute) \(minute == 1 ? languageManager.localize("minute_ago") : languageManager.localize("minutes_ago"))"
        } else {
            return languageManager.localize("just_now")
        }
    }
}

struct AddPostView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var storeManager: StoreManager
    
    @State private var caption = ""
    @State private var location = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker = false
    
    var onPostAdded: (CommunityPost) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(languageManager.localize("post_details"))) {
                    TextField(languageManager.localize("location"), text: $location)
                    
                    TextEditor(text: $caption)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if caption.isEmpty {
                                    Text(languageManager.localize("share_your_experience"))
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                        .padding(.top, 8)
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                }
                            }
                        )
                }
                
                Section(header: Text(languageManager.localize("add_photos"))) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(languageManager.localize("select_photos"))
                        }
                    }
                    .sheet(isPresented: $showImagePicker) {
                        ImagePicker(selectedImages: $selectedImages)
                    }
                    
                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<selectedImages.count, id: \.self) { index in
                                    if let imageData = selectedImages[index].pngData(),
                                       let imageUrl = URL(string: "data:image/png;base64,\(imageData.base64EncodedString())") {
                                        AsyncImage(url: imageUrl) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 80, height: 80)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 80, height: 80)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        Button(action: {
                                                            selectedImages.remove(at: index)
                                                        }) {
                                                            Image(systemName: "xmark.circle.fill")
                                                                .foregroundColor(.white)
                                                                .background(Color.black.opacity(0.5))
                                                                .clipShape(Circle())
                                                        }
                                                        .padding(4),
                                                        alignment: .topTrailing
                                                    )
                                            case .failure:
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 80, height: 80)
                                                    .overlay(
                                                        Image(systemName: "exclamationmark.triangle")
                                                            .font(.title)
                                                            .foregroundColor(.gray)
                                                    )
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            do {
                                try await PostService.shared.createPost(
                                    location: location,
                                    caption: caption,
                                    images: selectedImages
                                )
                                
                                let newPost = CommunityPost(
                                    id: UUID(),
                                    username: "you",
                                    userAvatar: "person.crop.circle.fill",
                                    location: location,
                                    caption: caption,
                                    images: selectedImages,
                                    likes: 0,
                                    comments: 0,
                                    timestamp: Date()
                                )
                                
                                DispatchQueue.main.async {
                                    onPostAdded(newPost)
                                    presentationMode.wrappedValue.dismiss()
                                }
                            } catch {
                                print("Error creating post: \(error)")
                            }
                        }
                    }) {
                        Text(languageManager.localize("share_post"))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(caption.isEmpty || location.isEmpty || selectedImages.isEmpty)
                }
            }
            .navigationTitle(languageManager.localize("new_post"))
            .navigationBarItems(
                leading: Button(languageManager.localize("cancel")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(languageManager.localize("post")) {
                    Task {
                        do {
                            try await PostService.shared.createPost(
                                location: location,
                                caption: caption,
                                images: selectedImages
                            )
                            
                            let newPost = CommunityPost(
                                id: UUID(),
                                username: "you",
                                userAvatar: "person.crop.circle.fill",
                                location: location,
                                caption: caption,
                                images: selectedImages,
                                likes: 0,
                                comments: 0,
                                timestamp: Date()
                            )
                            
                            onPostAdded(newPost)
                            presentationMode.wrappedValue.dismiss()
                        } catch {
                            print("Error creating post: \(error)")
                        }
                    }
                }
                .disabled(caption.isEmpty || location.isEmpty || selectedImages.isEmpty)
            )
        }
    }
}

struct CommunityPost: Identifiable {
    let id: UUID
    let username: String
    let userAvatar: String
    let location: String
    let caption: String
    let images: [UIImage]  
    let imageNames: [String]  
    let likes: Int
    let comments: Int
    let timestamp: Date
    
    init(id: UUID = UUID(), username: String, userAvatar: String, location: String, caption: String, 
         images: [UIImage] = [], imageNames: [String] = [], likes: Int = 0, comments: Int = 0, timestamp: Date = Date()) {
        self.id = id
        self.username = username
        self.userAvatar = userAvatar
        self.location = location
        self.caption = caption
        self.images = images
        self.imageNames = imageNames
        self.likes = likes
        self.comments = comments
        self.timestamp = timestamp
    }
}

#Preview {
    MediaView()
        .environmentObject(LanguageManager())
        .environmentObject(StoreManager())
}