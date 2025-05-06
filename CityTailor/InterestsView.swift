import SwiftUI

struct InterestsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var interests: [Interest] = loadInterests()
    
    var onComplete: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(interests.indices, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(interests[index].name)
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
                        
                        Text("Bewertung: \(Int(interests[index].rating))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Interessen")
            .navigationBarItems(trailing: Button("Fertig") {
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
                Interest(name: "Kunst", rating: 5),
                Interest(name: "Architektur", rating: 5),
                Interest(name: "Geschichte", rating: 5),
                Interest(name: "Natur", rating: 5),
                Interest(name: "Gastronomie", rating: 5),
                Interest(name: "Shopping", rating: 5),
                Interest(name: "Nachtleben", rating: 5),
                Interest(name: "Sport", rating: 5),
                Interest(name: "Technologie", rating: 5),
                Interest(name: "Musik", rating: 5),
                Interest(name: "Reisen", rating: 5)
            ]
        }
    }
}