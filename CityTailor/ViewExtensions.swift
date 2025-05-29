import SwiftUI
import UIKit

class TabSelection: ObservableObject {
    @Published var selectedTab: Int = 2
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            TabBarButton(iconName: "doc.text.fill", title: languageManager.localize("plans"), 
                         isSelected: selectedTab == 0, hasBackground: false) {
                selectedTab = 0
            }
            
            TabBarButton(iconName: "sparkles", title: languageManager.localize("discover"), 
                         isSelected: selectedTab == 1, hasBackground: false) {
                selectedTab = 1
            }

            TabBarButton(iconName: "map", title: languageManager.localize("map"), 
                         isSelected: selectedTab == 2, hasBackground: true) {
                selectedTab = 2
            }

            TabBarButton(iconName: "square.split.2x2.fill", title: languageManager.localize("community"), 
                         isSelected: selectedTab == 3, hasBackground: false) {
                selectedTab = 3
            }
            
            TabBarButton(iconName: "gear", title: languageManager.localize("settings"), 
                         isSelected: selectedTab == 4, hasBackground: false) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .padding(.bottom, 20)
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color.white)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: -2)
        .frame(maxWidth: .infinity)
    }
}

struct TabBarButton: View {
    let iconName: String
    let title: String
    let isSelected: Bool
    let hasBackground: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
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
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray5))
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

class DateFormatterUtils {
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        let dateFormat = UserDefaults.standard.integer(forKey: "dateFormat")
        
        switch dateFormat {
        case AppSettings.DateFormat.system.rawValue:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        case AppSettings.DateFormat.european.rawValue:
            formatter.dateFormat = "dd.MM.yyyy"
        case AppSettings.DateFormat.american.rawValue:
            formatter.dateFormat = "MM/dd/yyyy"
        case AppSettings.DateFormat.iso.rawValue:
            formatter.dateFormat = "yyyy-MM-dd"
        default:
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        
        return formatter.string(from: date)
    }
    
    static func formatDateString(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        return formatDate(date)
    }
    
    static func formatDateShort(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM."
        return outputFormatter.string(from: date)
    }
}