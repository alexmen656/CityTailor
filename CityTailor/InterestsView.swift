import SwiftUI

struct InterestsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var languageManager: LanguageManager
    @State private var interests: [Interest] = loadInterests()
    
    var onComplete: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(interests.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(languageManager.localize(interests[index].name))
                            .font(.headline)
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Slider(value: $interests[index].rating, in: 1...10, step: 1)
                            
                            Text("10")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Text(ratingText(interests[index].rating))
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle(languageManager.localize("interests"))
            .navigationBarItems(trailing: Button(languageManager.localize("done")) {
                saveInterests()
                if let onComplete = onComplete {
                    onComplete()
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            })
        }
    }
    
    func saveInterests() {
        let interestDicts = interests.map { ["name": $0.name, "rating": $0.rating] }
        UserDefaults.standard.set(interestDicts, forKey: "userInterests")
    }
    
    static func loadInterests() -> [Interest] {
        if let savedInterests = UserDefaults.standard.array(forKey: "userInterests") as? [[String: Any]] {
            return savedInterests.compactMap { dict in
                guard let name = dict["name"] as? String,
                      let rating = dict["rating"] as? Double else {
                    return nil
                }
                return Interest(name: name, rating: rating)
            }
        } else {
            return [
                Interest(name: "art", rating: 5),
                Interest(name: "architecture", rating: 5),
                Interest(name: "history", rating: 5),
                Interest(name: "nature", rating: 5),
                Interest(name: "gastronomy", rating: 5),
                Interest(name: "shopping", rating: 5),
                Interest(name: "nightlife", rating: 5),
                Interest(name: "sport", rating: 5),
                Interest(name: "technology", rating: 5),
                Interest(name: "music", rating: 5),
                Interest(name: "travel", rating: 5)
            ]
        }
    }
    
    private func ratingText(_ value: Double) -> String {
        return "\(languageManager.localize("rating")): \(Int(value))"
    }
}