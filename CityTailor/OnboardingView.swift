import SwiftUI

struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showingInterests = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "map")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(languageManager.localize("welcome_to_citytailor"))
                .font(.largeTitle)
                .bold()
            
            Text(languageManager.localize("personalize_travel_plans"))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showingInterests = true
            }) {
                Text(languageManager.localize("set_interests"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
            
            Button(action: {
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                isFirstLaunch = false
            }) {
                Text(languageManager.localize("skip"))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 30)
        }
        .padding()
        .fullScreenCover(isPresented: $showingInterests) {
            InterestsView(onComplete: {
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                isFirstLaunch = false
            })
        }
    }
}

#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
        .environmentObject(LanguageManager())
}