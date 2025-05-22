import SwiftUI

struct BudgetLevelSelector: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Binding var selectedBudgetLevel: BudgetLevel?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BudgetLevel.allCases, id: \.self) { budgetLevel in
                    Button(action: {
                        withAnimation {
                            selectedBudgetLevel = budgetLevel
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedBudgetLevel == budgetLevel ? Color.blue : Color.blue.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                
                                Text(budgetLevel.symbol)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selectedBudgetLevel == budgetLevel ? .white : .blue)
                            }
                            .overlay(
                                Circle()
                                    .stroke(selectedBudgetLevel == budgetLevel ? Color.blue : Color.clear, lineWidth: 2)
                                    .frame(width: 52, height: 52)
                            )
                            
                            Text(budgetLevel.localizedName(languageManager: languageManager))
                                .font(.caption)
                                .fontWeight(selectedBudgetLevel == budgetLevel ? .semibold : .regular)
                                .foregroundColor(selectedBudgetLevel == budgetLevel ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 70, height: 32)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: 90)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

struct TransportationTypeSelector: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Binding var selectedTransportationType: TransportationType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TransportationType.allCases, id: \.self) { transportationType in
                    Button(action: {
                        withAnimation {
                            selectedTransportationType = transportationType
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: transportationType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedTransportationType == transportationType ? .white : .blue)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(selectedTransportationType == transportationType ? Color.blue : Color.blue.opacity(0.1))
                                )
                            
                            Text(transportationType.localizedName(languageManager: languageManager))
                                .font(.caption)
                                .foregroundColor(selectedTransportationType == transportationType ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 70, height: 32)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: 90)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

struct TravelTypeSelector: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Binding var selectedTravelType: TravelType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TravelType.allCases, id: \.self) { travelType in
                    Button(action: {
                        withAnimation {
                            selectedTravelType = travelType
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: travelType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedTravelType == travelType ? .white : .blue)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(selectedTravelType == travelType ? Color.blue : Color.blue.opacity(0.1))
                                )
                            
                            Text(travelType.localizedName(languageManager: languageManager))
                                .font(.caption)
                                .foregroundColor(selectedTravelType == travelType ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 70, height: 32)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: 90)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

struct TravelModeSelector: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @Binding var selectedTravelMode: TravelMode?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TravelMode.allCases, id: \.self) { travelMode in
                    Button(action: {
                        withAnimation {
                            selectedTravelMode = travelMode
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: travelMode.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedTravelMode == travelMode ? .white : .blue)
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(selectedTravelMode == travelMode ? Color.blue : Color.blue.opacity(0.1))
                                )
                            
                            Text(travelMode.localizedName(languageManager: languageManager))
                                .font(.caption)
                                .foregroundColor(selectedTravelMode == travelMode ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 70, height: 32)
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(height: 90)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}

struct DateSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var languageManager: LanguageManager
    
    let locationName: String
    var onTravelPlanReceived: ((TravelPlan) -> Void)? = nil
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
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
    
    @State private var selectedTravelType: TravelType? = .solo
    @State private var selectedTransportationType: TransportationType? = .walking
    @State private var selectedTravelMode: TravelMode? = .moderate
    @State private var selectedBudgetLevel: BudgetLevel? = .medium
    @State private var showAdvancedSettings: Bool = false
    
    var tripLengthInDays: Int {
        (Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0) + 1
    } 
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(languageManager.localize("destination"))) {
                    HStack {
                        Text(languageManager.localize("location") + ":")
                        Spacer()
                        Text(locationName)
                            .bold()
                    }
                }
                
                Section(header: Text(languageManager.localize("travel_period"))) {
                    DatePicker(languageManager.localize("arrival_date"), selection: $startDate, displayedComponents: .date)
                    
                    DatePicker(languageManager.localize("departure_date"), selection: $endDate, in: startDate..., displayedComponents: .date)
                    
                    HStack {
                        Text(languageManager.localize("duration") + ":")
                        Spacer()
                        Text("\(tripLengthInDays) \(tripLengthInDays == 1 ? languageManager.localize("day_singular") : languageManager.localize("days"))")
                            .bold()
                    }
                }
                
                Section(header: Text(languageManager.localize("travel_type"))) {
                    TravelTypeSelector(selectedTravelType: $selectedTravelType)
                }
                
                Section(header: Text(languageManager.localize("advanced_settings"))) {
                    DisclosureGroup(
                        isExpanded: $showAdvancedSettings,
                        content: {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(languageManager.localize("transportation_type"))
                                    .font(.headline)
                                    .padding(.top, 8)
                                
                                TransportationTypeSelector(selectedTransportationType: $selectedTransportationType)
                                    .padding(.bottom, 8)
                                
                                if storeManager.isPremium() {
                                    Text(languageManager.localize("travel_mode"))
                                        .font(.headline)
                                        .padding(.top, 8)
                                    
                                    TravelModeSelector(selectedTravelMode: $selectedTravelMode)
                                        .padding(.bottom, 8)
                                    
                                    Text(languageManager.localize("budget_level"))
                                        .font(.headline)
                                        .padding(.top, 8)
                                    
                                    BudgetLevelSelector(selectedBudgetLevel: $selectedBudgetLevel)
                                        .padding(.bottom, 8)
                                } else {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "crown.fill")
                                                .foregroundColor(.yellow)
                                                .font(.system(size: 20))
                                            Text(languageManager.localize("premium_features"))
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }
                                        
                                       /* Text("1.")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 8)*/
                                            
                                        HStack {
                                            Image(systemName: "figure.walk")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                            Text(languageManager.localize("travel_mode"))
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Text(languageManager.localize("travel_mode_premium_description"))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Divider()
                                            .padding(.vertical, 8)
                                        
                                       /* Text("2.")
                                            .font(.headline)
                                            .foregroundColor(.secondary)*/
                                            
                                        HStack {
                                            Image(systemName: "dollarsign.circle")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 16))
                                            Text(languageManager.localize("budget_level"))
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        }
                                        
                                        Text(languageManager.localize("budget_level_premium_description"))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                            .padding(.top, 2)
                                        
                                        Button(action: {
                                            showPremiumView = true
                                        }) {
                                            Text(languageManager.localize("upgrade_to_premium"))
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .cornerRadius(10)
                                        }
                                        .padding(.top, 5)
                                    }
                                    .padding(.vertical, 10)
                                }
                            }
                        },
                        label: {
                            HStack {
                                Text(languageManager.localize("advanced_settings"))
                                    //.font(.headline)
                                /*Spacer()
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)*/
                            }
                        }
                    )
                    .animation(.easeInOut, value: showAdvancedSettings)
                }
                
                Section {
                    Button(action: {
                        if !storeManager.isPremium() && !TravelPlanStore.shared.canSaveTravelPlan(isPremium: false, context: viewContext) {
                            alertTitle = languageManager.localize("limit_reached")
                            alertMessage = languageManager.localize("limit_reached_message").replacingOccurrences(of: "{0}", with: "\(TravelPlanStore.FREE_PLAN_LIMIT)")
                            showPremiumOffer = true
                            showAlert = true
                        } else {
                            sendDataToBackend()
                        }
                    }) {
                        if isLoading {
                            VStack(spacing: 10) {
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
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                }
                            }
                        } else {
                            Text(languageManager.localize("generate_plan"))
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                }
                
                if !storeManager.isPremium() {
                    let remaining = TravelPlanStore.shared.getRemainingFreePlans(context: viewContext)
                    
                    Section(header: Text(languageManager.localize("free_account"))) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text(languageManager.localize("remaining_free_plans"))
                            Spacer()
                            
                            Text("\(remaining) \(languageManager.localize("of")) \(TravelPlanStore.FREE_PLAN_LIMIT)")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            showPremiumView = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text(languageManager.localize("upgrade_to_premium"))
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
            .navigationTitle(languageManager.localize("travel_period"))
            .navigationBarItems(trailing: Button(languageManager.localize("close")) {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                if showPremiumOffer {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        primaryButton: .default(Text(languageManager.localize("upgrade_to_premium"))) {
                            showPremiumView = true
                        },
                        secondaryButton: .cancel(Text(languageManager.localize("cancel")))
                    )
                } else {
                    return Alert(
                        title: Text(alertTitle),
                        message: Text(alertMessage),
                        dismissButton: .default(Text(languageManager.localize("ok")))
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
        updateGenerationStatusText()
        
        simulateProgressForStep()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let userInterests = InterestsView.loadInterests()
        
        let interestsData = userInterests.map { [
            "name": $0.name,
            "rating": $0.rating
        ] }
        
        var tripData: [String: Any] = [
            "location": locationName,
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "durationInDays": tripLengthInDays,
            "interests": interestsData,
            "language": languageManager.currentLanguage.code 
        ]
        
        if let travelType = selectedTravelType {
            tripData["travelType"] = travelType.rawValue
        }
        
        if let transportationType = selectedTransportationType {
            tripData["transportationType"] = transportationType.rawValue
        }
        
        if let travelMode = selectedTravelMode {
            tripData["travelMode"] = travelMode.rawValue
        }
        
        if storeManager.isPremium(), let budgetLevel = selectedBudgetLevel {
            tripData["budgetLevel"] = budgetLevel.rawValue
        }
        
        guard let url = URL(string: "https://city-tailor-backend-k9s6rk7eu-alexmen656s-projects.vercel.app/api/trips") else {
            self.alertTitle = languageManager.localize("backend_notification")
            self.alertMessage = languageManager.localize("invalid_url")
            self.showAlert = true
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let isPremium = storeManager.isPremium()
        request.addValue(isPremium ? "true" : "false", forHTTPHeaderField: "X-Premium-Status")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tripData)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertTitle = languageManager.localize("backend_notification")
                        self.alertMessage = languageManager.localize("server_error_retry")
                        self.showAlert = true
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertTitle = languageManager.localize("backend_notification")
                        self.alertMessage = languageManager.localize("server_error_retry")
                        self.showAlert = true
                    }
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201, let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let backendResponse = try decoder.decode(BackendResponse.self, from: data)
                        
                        DispatchQueue.main.async {
                            if self.currentGenerationStep >= self.generationSteps {
                                self.processResponse(backendResponse)
                            } else {
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
                            self.alertTitle = languageManager.localize("backend_notification")
                            self.alertMessage = languageManager.localize("data_processing_error").replacingOccurrences(of: "{0}", with: error.localizedDescription)
                            self.showAlert = true
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.alertTitle = languageManager.localize("backend_notification")
                        self.alertMessage = languageManager.localize("server_error_retry")
                        self.showAlert = true
                    }
                }
            }.resume()
        } catch {
            self.isLoading = false
            self.alertTitle = languageManager.localize("backend_notification")
            self.alertMessage = languageManager.localize("json_error").replacingOccurrences(of: "{0}", with: error.localizedDescription)
            self.showAlert = true
        }
    }
    
    private func updateGenerationStatusText() {
        if currentGenerationStep == 0 {
            generationStatusText = languageManager.localize("preparing_generation")
        } else if currentGenerationStep <= tripLengthInDays {
            generationStatusText = languageManager.localize("generating_day")
                .replacingOccurrences(of: "{0}", with: "\(currentGenerationStep)")
                .replacingOccurrences(of: "{1}", with: "\(tripLengthInDays)")
        } else {
            generationStatusText = languageManager.localize("finalizing_plan")
        }
    }
    
    private func simulateProgressForStep() {
        guard currentGenerationStep < generationSteps else { return }
        
        updateGenerationStatusText()
        
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
    
    private func processResponse(_ backendResponse: BackendResponse) {
        self.travelPlan = backendResponse.data
        self.isLoading = false
        
        if let onTravelPlanReceived = self.onTravelPlanReceived {
            onTravelPlanReceived(backendResponse.data)
        }
        
        self.presentationMode.wrappedValue.dismiss()
    }
}
