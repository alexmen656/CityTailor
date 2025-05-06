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
            
            Text("Willkommen bei CityTailor")
                .font(.largeTitle)
                .bold()
            
            Text("Personalisieren Sie Ihre Reisepläne, indem Sie uns mitteilen, woran Sie interessiert sind")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showingInterests = true
            }) {
                Text("Interessen festlegen")
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
                Text("Überspringen")
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