import SwiftUI

struct DateSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var storeManager: StoreManager
    
    let locationName: String
    var onTravelPlanReceived: ((TravelPlan) -> Void)? = nil
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Backend-Benachrichtigung"
    @State private var showPremiumOffer = false
    
    @State private var travelPlan: TravelPlan?
    @State private var showTravelPlan = false
    @State private var selectedDayNumber: Int = 1
    @State private var showPremiumView = false
    
    var tripLengthInDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Reiseziel")) {
                    HStack {
                        Text("Ort:")
                        Spacer()
                        Text(locationName)
                            .bold()
                    }
                }
                
                Section(header: Text("Reisezeitraum")) {
                    DatePicker("Anreisedatum", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("Abreisedatum", selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    HStack {
                        Text("Aufenthaltsdauer:")
                        Spacer()
                        Text("\(tripLengthInDays) \(tripLengthInDays == 1 ? "Tag" : "Tage")")
                            .bold()
                    }
                }
                
                Section {
                    Button(action: {
                        // Prüfe, ob der Nutzer noch einen Plan erstellen darf
                        if !storeManager.isPremium() && !TravelPlanStore.shared.canSaveTravelPlan(isPremium: false, context: viewContext) {
                            alertTitle = "Limit erreicht"
                            alertMessage = "Sie haben das Maximum von \(TravelPlanStore.FREE_PLAN_LIMIT) Reiseplänen für die kostenlose Version erreicht. Upgrade auf Premium für unbegrenzte Reisepläne."
                            showPremiumOffer = true
                            showAlert = true
                        } else {
                            sendDataToBackend()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Generate Travel Plan")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                }
                
                // Separate Sektion für die Premium-Info
                if !storeManager.isPremium() {
                    let remaining = TravelPlanStore.shared.getRemainingFreePlans(context: viewContext)
                    
                    Section(header: Text("Kostenloses Konto")) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Verbleibende kostenlose Pläne")
                            Spacer()
                            
                            Text("\(remaining) von \(TravelPlanStore.FREE_PLAN_LIMIT)")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showPremiumView = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text("Upgrade auf Premium")
                                    .foregroundColor(.blue)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Reiseplanung")
            .navigationBarItems(trailing: Button("Schließen") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                if showPremiumOffer {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        primaryButton: .default(Text("Upgrade auf Premium")) {
                            showPremiumView = true
                        },
                        secondaryButton: .cancel(Text("Abbrechen"))
                    )
                } else {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .sheet(isPresented: $showTravelPlan) {
                if let plan = travelPlan {
                    TravelPlanView(travelPlan: plan, selectedDay: $selectedDayNumber)
                }
            }
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
        }
    }
    
    func sendDataToBackend() {
        isLoading = true
        
        // Für API-Anfragen benötigen wir immer das ISO-Format (YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Lade die Nutzerinteressen
        let userInterests = InterestsView.loadInterests()
        
        // Erstelle ein Dictionary mit den Top-Interessen und ihren Bewertungen
        let interestsData = userInterests.map { [
            "name": $0.name,
            "rating": $0.rating
        ] }
        
        let tripData: [String: Any] = [
            "location": locationName,
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "durationInDays": tripLengthInDays,
            "interests": interestsData  // Füge Interessen zum Request hinzu
        ]
        
        guard let url = URL(string: "https://city-tailor-backend-7yq4wmveb-alexmen656s-projects.vercel.app/api/trips") else {
            self.alertMessage = "Ungültige URL"
            self.showAlert = true
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tripData)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.alertMessage = "Fehler: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        self.alertMessage = "Ungültige Serverantwort"
                        self.showAlert = true
                        return
                    }
                    
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                        if let data = data {
                            do {
                                let decoder = JSONDecoder()
                                let backendResponse = try decoder.decode(BackendResponse.self, from: data)
                                self.travelPlan = backendResponse.data
                                
                                // Gib den Travel Plan an die ContentView zurück
                                if let onTravelPlanReceived = self.onTravelPlanReceived {
                                    onTravelPlanReceived(backendResponse.data)
                                }
                                
                                self.presentationMode.wrappedValue.dismiss()
                            } catch {
                                print("Fehler beim Dekodieren: \(error)")
                                self.alertMessage = "Fehler beim Verarbeiten der Daten: \(error.localizedDescription)"
                                self.showAlert = true
                            }
                        }
                    } else {
                        self.alertMessage = "Server-Fehler: Status \(httpResponse.statusCode)"
                        self.showAlert = true
                    }
                }
            }.resume()
        } catch {
            self.isLoading = false
            self.alertMessage = "Fehler beim Erstellen der JSON-Daten: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
}