import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    var searchAction: () -> Void
    @Binding var showSettings: Bool
    @Binding var showSuggestions: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
                
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("Stadt eingeben...")
                            .foregroundColor(.gray)
                            .allowsHitTesting(false)
                    }
                    
                    // Vereinfachtes TextField ohne zusätzliche Modifikatoren, die den Fokus stören könnten
                    TextField("", text: $text)
                        .foregroundColor(.primary)
                        .focused($isFocused)
                        .onSubmit {
                            searchAction()
                        }
                }
                .onTapGesture {
                    isSearching = true
                    isFocused = true
                }
                
                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    self.showSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                }
            }
            .padding(10)
            .background(Color(UIColor.systemBackground))
            .if(showSuggestions && !text.isEmpty) { view in
                view.cornerRadius(10, corners: [.topLeft, .topRight])
            }
            .if(!showSuggestions || text.isEmpty) { view in
                view.cornerRadius(10)
            }
        }
        .onAppear {
            if isSearching {
                isFocused = true
            }
        }
        // WICHTIG: KEINE onChange-Handler für text mehr!
    }
}