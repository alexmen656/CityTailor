import SwiftUI
import UIKit

class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 1
}

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

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        HStack {
            TabBarButton(iconName: "map.fill", title: languageManager.localize("plans"), 
                         isSelected: selectedTab == 0, hasBackground: false) {
                selectedTab = 0
            }
            
            TabBarButton(iconName: "map", title: languageManager.localize("map"), 
                         isSelected: selectedTab == 1, hasBackground: true) {
                selectedTab = 1
            }
            
            TabBarButton(iconName: "gear", title: languageManager.localize("settings"), 
                         isSelected: selectedTab == 2, hasBackground: false) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .padding(.bottom, 20)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        .frame(maxWidth: .infinity)
    }
}

struct TabBarButton: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let hasBackground: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            DispatchQueue.main.async {
                self.action()
            }
        }) {
            VStack(spacing: 4) {
                if hasBackground {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: iconName)
                            .foregroundColor(isSelected ? .blue : .gray)
                            .font(.system(size: 20))
                    }
                } else {
                    Image(systemName: iconName)
                        .foregroundColor(isSelected ? .blue : .gray)
                        .font(.system(size: 20))
                }
                
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}