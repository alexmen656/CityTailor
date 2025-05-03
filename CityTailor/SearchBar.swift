import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isSearching: Bool
    var searchAction: () -> Void
    @Binding var showSettings: Bool
    @Binding var showSuggestions: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
                
                TextField("Stadt eingeben...", text: $text, onCommit: {
                    searchAction()
                })
                .foregroundColor(.primary)
                
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
           // .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            if isSearching {
                Button("Abbrechen") {
                    self.text = ""
                    self.isSearching = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}

// Hilfserweiterung für die Eckenrundung
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, 
                                byRoundingCorners: corners, 
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}