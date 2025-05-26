import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var languageManager: LanguageManager
    
    private let featuredItems = [
        FeaturedItem(
            title: "Brandenburger Tor",
            description: "Berlins bekanntestes Wahrzeichen",
            imageName: "building.columns.fill",
            color: .blue
        ),
        FeaturedItem(
            title: "Schloss Neuschwanstein",
            description: "Märchenschloss in den Alpen",
            imageName: "house.fill",
            color: .purple
        ),
        FeaturedItem(
            title: "Hamburger Hafen",
            description: "Größter Seehafen Deutschlands",
            imageName: "ferry.fill",
            color: .teal
        )
    ]
    
    private let categories = [
        CategoryItem(
            title: "landmarks",
            icon: "building.columns.fill",
            color: .blue,
            items: ["Brandenburger Tor", "Kölner Dom", "Frauenkirche"]
        ),
        CategoryItem(
            title: "food",
            icon: "fork.knife",
            color: .orange,
            items: ["Currywurst", "Schnitzel", "Bretzel"]
        ),
        CategoryItem(
            title: "activities",
            icon: "figure.hiking",
            color: .green,
            items: ["Wandern", "Radfahren", "Segeln"]
        ),
        CategoryItem(
            title: "events",
            icon: "calendar",
            color: .red,
            items: ["Oktoberfest", "Karneval", "Christkindlmarkt"]
        ),
        CategoryItem(
            title: "trending",
            icon: "flame.fill",
            color: .pink,
            items: ["Street Art Tour", "Food Markets", "Rooftop Bars"]
        ),
        CategoryItem(
            title: "local_tips",
            icon: "star.fill",
            color: .yellow,
            items: ["Geheime Spots", "Insider Cafés", "Local Markets"]
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.localize("featured"))
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(featuredItems) { item in
                                    FeaturedCard(item: item)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(languageManager.localize("categories"))
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            ForEach(categories) { category in
                                CategoryCard(category: category)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(languageManager.localize("discover"))
        }
    }
}

struct FeaturedItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

struct CategoryItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let items: [String]
}

struct FeaturedCard: View {
    let item: FeaturedItem
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(item.color.opacity(0.2))
                
                Image(systemName: item.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(item.color)
            }
            .frame(width: 280, height: 180)
            
            Text(item.title)
                .font(.headline)
                .padding(.top, 4)
            
            Text(item.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 280)
    }
}

struct CategoryCard: View {
    let category: CategoryItem
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(category.color)
            }
            
            Text(languageManager.localize(category.title))
                .font(.headline)
            
            Text("\(category.items.count) " + languageManager.localize("items"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    DiscoverView()
        .environmentObject(LanguageManager())
}