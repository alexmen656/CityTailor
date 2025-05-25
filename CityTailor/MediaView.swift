import SwiftUI

struct MediaView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var storeManager: StoreManager
    
    @State private var showingAddPostSheet = false
    @State private var userPosts: [CommunityPost] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    
                    HStack {
                        Text(languageManager.localize("community_feed"))
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAddPostSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                    }
                    .padding(.vertical, 8)
                    
                    
                    if userPosts.isEmpty {
                        ForEach(samplePosts) { post in
                            PostCard(post: post)
                        }
                    } else {
                        ForEach(userPosts) { post in
                            PostCard(post: post)
                        }
                    }
                }
                .padding(.bottom, 70)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddPostSheet) {
                AddPostView(onPostAdded: { post in
                    userPosts.insert(post, at: 0)
                })
            }
            .onAppear {
                loadPosts()
            }
        }
    }
    
    private func loadPosts() {
        
        
    }
    
    
    private var samplePosts: [CommunityPost] = [
        CommunityPost(
            id: UUID(),
            username: "traveler123",
            userAvatar: "person.crop.circle.fill",
            location: "Paris",
            caption: "Just spent an amazing day exploring the Louvre Museum! 🎨",
            imageNames: ["paris1"],
            likes: 42,
            comments: 7,
            timestamp: Date().addingTimeInterval(-86400) 
        ),
        CommunityPost(
            id: UUID(),
            username: "wanderlust_explorer",
            userAvatar: "person.crop.circle.fill",
            location: "Tokyo",
            caption: "The cherry blossoms in Ueno Park are incredible this time of year! 🌸",
            imageNames: ["tokyo1"],
            likes: 89,
            comments: 12,
            timestamp: Date().addingTimeInterval(-172800) 
        ),
        CommunityPost(
            id: UUID(),
            username: "city_hopper",
            userAvatar: "person.crop.circle.fill",
            location: "Barcelona",
            caption: "La Sagrada Familia is a must-see architectural masterpiece! 🏛️",
            imageNames: ["barcelona1"],
            likes: 65,
            comments: 9,
            timestamp: Date().addingTimeInterval(-259200) 
        )
    ]
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
            
            
            if !post.images.isEmpty {
                Image(uiImage: post.images[0])
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
            } else if !post.imageNames.isEmpty, let firstImage = post.imageNames.first {
                if UIImage(named: firstImage) != nil {
                    Image(firstImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipped()
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
                                    Image(uiImage: selectedImages[index])
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
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Section {
                    Button(action: {
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
                    let newPost = CommunityPost(
                        id: UUID(),
                        username: "you",
                        userAvatar: "person.crop.circle.fill",
                        location: location,
                        caption: caption,
                        imageNames: [], 
                        likes: 0,
                        comments: 0,
                        timestamp: Date()
                    )
                    
                    onPostAdded(newPost)
                    presentationMode.wrappedValue.dismiss()
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