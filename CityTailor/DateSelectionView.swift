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
    
    @State private var currentGenerationStep = 0
    @State private var generationSteps = 0
    @State private var generationProgress: Float = 0.0
    @State private var targetProgress: Float = 0.0
    @State private var generationStatusText = ""
    @State private var animationTimer: Timer? = nil
    
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
                            VStack(spacing: 10) {
                                // Fortschrittsbalken und Status anzeigen, wenn die Generierung läuft
                                if generationSteps > 0 {
                                    VStack(spacing: 6) {
                                        ProgressView(value: generationProgress, total: 1.0)
                                            .progressViewStyle(LinearProgressViewStyle())
                                            .animation(.easeInOut, value: generationProgress)
                                        
                                        HStack {
                                            Text(generationStatusText)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(generationProgress * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                } else {
                                    // Standard-Ladeindikator, wenn die Generierung noch nicht begonnen hat
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
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
        
        self.generationSteps = tripLengthInDays + 2 
        self.currentGenerationStep = 0
        self.generationProgress = 0.0
        self.targetProgress = 0.0
        self.generationStatusText = "Bereite die Generierung vor..."
        
        simulateProgressForStep()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let userInterests = InterestsView.loadInterests()
        
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
                // Die eigentliche API-Anfrage wurde schon beim Start abgesendet.
                // Wir warten mit der Verarbeitung der Antwort, bis die animierte Generierung abgeschlossen ist
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Fehler: \(error.localizedDescription)"
                        self.showAlert = true
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertMessage = "Ungültige Serverantwort"
                        self.showAlert = true
                    }
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201, let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let backendResponse = try decoder.decode(BackendResponse.self, from: data)
                        
                        // Wir speichern die Antwort, aber verarbeiten sie erst,
                        // wenn die animierte Generierung abgeschlossen ist
                        DispatchQueue.main.async {
                            if self.currentGenerationStep >= self.generationSteps {
                                self.processResponse(backendResponse)
                            } else {
                                // Wenn die Generierung noch läuft, warten wir bis zur Fertigstellung
                                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                    if self.currentGenerationStep >= self.generationSteps {
                                        timer.invalidate()
                                        self.processResponse(backendResponse)
                                    }
                                }
                            }
                        }
                    } catch {
                        print("Fehler beim Dekodieren: \(error)")
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.alertMessage = "Fehler beim Verarbeiten der Daten: \(error.localizedDescription)"
                            self.showAlert = true
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
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
    
    // Hilfsfunction zur Simulation des Fortschritts
    private func simulateProgressForStep() {
        guard currentGenerationStep < generationSteps else { return }
        
        // Status-Text basierend auf aktuellem Schritt aktualisieren
        if currentGenerationStep == 0 {
            generationStatusText = "Bereite die Generierung vor..."
        } else if currentGenerationStep <= tripLengthInDays {
            generationStatusText = "Generiere Tag \(currentGenerationStep) von \(tripLengthInDays)..."
        } else {
            generationStatusText = "Finalisiere Reiseplan..."
        }
        
        targetProgress = Float(currentGenerationStep) / Float(generationSteps)
        
        let delay: Double
        if currentGenerationStep == 0 {
            delay = 2.2
        } else if currentGenerationStep <= tripLengthInDays {
            delay = 3.3 
        } else {
            delay = 2.0 
        }
        
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if self.generationProgress < self.targetProgress {
                self.generationProgress += 0.01
            } else {
                timer.invalidate()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.currentGenerationStep += 1
            self.simulateProgressForStep()
        }
    }
    
    // Verarbeiten der Backend-Antwort
    private func processResponse(_ backendResponse: BackendResponse) {
        self.travelPlan = backendResponse.data
        self.isLoading = false
        
        // Gib den Travel Plan an die ContentView zurück
        if let onTravelPlanReceived = self.onTravelPlanReceived {
            onTravelPlanReceived(backendResponse.data)
        }
        
        self.presentationMode.wrappedValue.dismiss()
    }
}