import SwiftUI
import UniformTypeIdentifiers

struct TravelPlanView: View {
    let travelPlan: TravelPlan
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDay: Int
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showPremiumView = false
    @State private var showShareSheet = false
    @State private var showEmptyDetailView = false
    @State private var showGetYourGuideView = false
    @State private var selectedActivity: Activity?
    @State private var getYourGuideURL: URL?
    @State private var pdfData: Data?
    var onActivitySelected: ((Activity) -> Void)? = nil
    
    init(travelPlan: TravelPlan, selectedDay: Binding<Int>, onActivitySelected: ((Activity) -> Void)? = nil) {
        self.travelPlan = travelPlan
        self._selectedDay = selectedDay
        self.onActivitySelected = onActivitySelected
        
        print("DEBUG: TravelPlanView init for \(travelPlan.location)")
        print("DEBUG: Initial selected day: \(selectedDay.wrappedValue)")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack {
                    Text(travelPlan.location)
                        .font(.largeTitle)
                        .bold()
                        .padding(.top)
                    
                    Text("\(formatDateString(travelPlan.period.startDate)) \(languageManager.localize("to")) \(formatDateString(travelPlan.period.endDate))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
                .onAppear {
                    print("DEBUG: TravelPlanView appeared for \(travelPlan.location)")
                    print("DEBUG: Selected day: \(selectedDay)")
                    if let dailyPlans = travelPlan.dailyPlans {
                        print("DEBUG: Available days: \(dailyPlans.map { $0.dayNumber })")
                        print("DEBUG: First day activities count: \(dailyPlans.first?.activities.count ?? 0)")
                    } else {
                        print("DEBUG: No daily plans available")
                    }
                }
                
                if let dailyPlans = travelPlan.dailyPlans, !dailyPlans.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(dailyPlans) { day in
                                DayButton(
                                    dayNumber: day.dayNumber,
                                    date: formatDateShort(day.date),
                                    isSelected: selectedDay == day.dayNumber
                                ) {
                                    print("DEBUG: Day \(day.dayNumber) selected")
                                    selectedDay = day.dayNumber
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                    .onAppear {
                        let validDayNumbers = dailyPlans.map { $0.dayNumber }
                        if !validDayNumbers.contains(selectedDay) {
                            if let firstDay = dailyPlans.first {
                                print("DEBUG: Selected day \(selectedDay) not valid, switching to day \(firstDay.dayNumber)")
                                selectedDay = firstDay.dayNumber
                            }
                        }
                    }
                    
                    if let dayPlan = dailyPlans.first(where: { $0.dayNumber == selectedDay }) {
                        List {
                            ForEach(dayPlan.activities) { activity in
                                VStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack {
                                            Text(activity.time)
                                                .font(.headline)
                                                .foregroundColor(.blue)
                                            
                                            Spacer()
                                            
                                            Text(translateCategory(activity.category))
                                                .font(.caption)
                                                .padding(5)
                                                .background(categoryColor(for: activity.category))
                                                .foregroundColor(.white)
                                                .cornerRadius(5)
                                        }
                                        
                                        Text(activity.title)
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(.primary)
                                        
                                        Text(activity.description)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                        
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.red)
                                            Text(activity.displayAddress)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(.trailing, 4)
                                        .padding(.bottom, 8)
                                        
                                        HStack(spacing: 10) {
                                            if activity.isTicketable {
                                                Button(action: {
                                                    if let url = activity.getYourGuideURL {
                                                        getYourGuideURL = url
                                                        showGetYourGuideView = true
                                                    }
                                                }) {
                                                    HStack {
                                                        Image(systemName: "ticket.fill")
                                                            .foregroundColor(.white)
                                                        Text(languageManager.localize("get_tickets"))
                                                            .foregroundColor(.white)
                                                            .fontWeight(.semibold)
                                                    }
                                                    .padding(.vertical, 8)
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.green)
                                                    .cornerRadius(8)
                                                }
                                            }
                                            
                                            Button(action: {
                                                selectedActivity = activity
                                                showEmptyDetailView = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "location.fill")
                                                        .foregroundColor(.white)
                                                    Text(languageManager.localize("navigate"))
                                                        .foregroundColor(.white)
                                                        .fontWeight(.semibold)
                                                }
                                                .padding(.vertical, 8)
                                                .frame(maxWidth: .infinity)
                                                .background(Color.blue)
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                    .padding(.top, 3)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 8)
                            }
                            
                            if let recommendations = travelPlan.recommendations {
                                Section(header: Text(languageManager.localize("recommendations"))) {
                                    if !recommendations.food.isEmpty {
                                        DisclosureGroup(languageManager.localize("food_drinks")) {
                                            ForEach(recommendations.food, id: \.self) { food in
                                                Label(food, systemImage: "fork.knife")
                                            }
                                        }
                                    }
                                    
                                    if !recommendations.transport.isEmpty {
                                        DisclosureGroup(languageManager.localize("transport")) {
                                            ForEach(recommendations.transport, id: \.self) { tip in
                                                Label(tip, systemImage: "tram.fill")
                                            }
                                        }
                                    }
                                    
                                    if !recommendations.tips.isEmpty {
                                        DisclosureGroup(languageManager.localize("useful_tips")) {
                                            ForEach(recommendations.tips, id: \.self) { tip in
                                                Label(tip, systemImage: "lightbulb.fill")
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Section {
                                Button(action: {
                                    if storeManager.isPremium() {
                                        exportPDF()
                                    } else {
                                        showPremiumView = true
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.doc")
                                            .font(.system(size: 18))
                                        Text(languageManager.localize("export_pdf"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    } else {
                        Spacer()
                        Text(languageManager.localize("no_activities_found"))
                            .onAppear {
                                print("DEBUG: No day plan found for day \(selectedDay)")
                                print("DEBUG: Available day numbers: \(dailyPlans.map { $0.dayNumber })")
                            }
                        Spacer()
                    }
                } else if let info = travelPlan.info {
                    Spacer()
                    Text(info)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else {
                    Spacer()
                    Text(languageManager.localize("no_plan_data"))
                        .onAppear {
                            print("DEBUG: No travel plan data available at all")
                        }
                    Spacer()
                }
            }
            .navigationBarItems(
                trailing: HStack(spacing: 16) {
                    Button(action: {
                        shareTravelPlan()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                    }
                    
                    Button(languageManager.localize("done")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
            .sheet(isPresented: $showPremiumView) {
                PremiumView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfData = pdfData {
                    ShareSheet(items: [pdfData])
                }
            }
            .sheet(isPresented: $showGetYourGuideView) {
                if let url = getYourGuideURL {
                    SafariView(url: url)
                }
            }
            .fullScreenCover(isPresented: $showEmptyDetailView) {
                if let activity = selectedActivity {
                    TicketableActivityDetailView(activity: activity)
                }
            }
        }
    }
    
    func formatDateShort(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM."
        return outputFormatter.string(from: date)
    }
    
    func formatDateString(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        
        let dateFormat = AppSettings.DateFormat(rawValue: settings.dateFormat) ?? .system
        switch dateFormat {
        case .system:
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .none
        case .european:
            outputFormatter.dateFormat = "dd.MM.yyyy"
        case .american:
            outputFormatter.dateFormat = "MM/dd/yyyy"
        case .iso:
            outputFormatter.dateFormat = "yyyy-MM-dd"
        }
        
        return outputFormatter.string(from: date)
    }
    
    func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    func translateCategory(_ category: String) -> String {
        guard let firstChar = category.first else { return category }
        return String(firstChar).uppercased() + category.dropFirst()
    }
    
    func categoryColor(for category: String) -> Color {
        let lowercasedCategory = category.lowercased()
        
        if ["kunst", "art", "arte"].contains(where: lowercasedCategory.contains) {
            return Color.purple
        }
        
        if ["geschichte", "history", "histoire", "historia", "storia"].contains(where: lowercasedCategory.contains) {
            return Color.orange
        }
        
        if ["architektur", "architecture", "arquitectura", "architettura"].contains(where: lowercasedCategory.contains) {
            return Color.blue
        }
        
        if ["gastronomie", "gastronomy", "gastronomía", "gastronomia", "essen", "food", "cuisine"].contains(where: lowercasedCategory.contains) {
            return Color.red
        }
        
        if ["shopping", "einkaufen", "compras", "achats"].contains(where: lowercasedCategory.contains) {
            return Color.pink
        }
        
        if ["nachtleben", "nightlife", "vida nocturna", "vie nocturne", "vita notturna"].contains(where: lowercasedCategory.contains) {
            return Color.indigo
        }
        
        if ["kultur", "culture", "cultura"].contains(where: lowercasedCategory.contains) {
            return Color.teal
        }
        
        if ["sightseeing", "besichtigung", "visites", "visitas", "visite"].contains(where: lowercasedCategory.contains) {
            return Color.green
        }
        
        return Color.gray
    }
    
    func exportPDF() {
        print("Starting PDF export")
        if let pdfData = PDFGenerator.generatePDF(from: travelPlan, languageManager: languageManager) {
            print("PDF generated successfully, size: \(pdfData.count) bytes")
            
            #if os(macOS)
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = "\(travelPlan.location)_TravelPlan.pdf"
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try pdfData.write(to: url)
                        print("PDF successfully saved at: \(url.path)")
                    } catch {
                        print("Failed to save PDF: \(error)")
                    }
                }
            }
            #else
            DispatchQueue.main.async {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(travelPlan.location)_TravelPlan.pdf")
                
                do {
                    try pdfData.write(to: tempURL)
                    print("PDF temporarily saved at: \(tempURL.path)")
                    
                    let activityVC = UIActivityViewController(
                        activityItems: [tempURL], 
                        applicationActivities: nil
                    )
                    
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        var topController = rootVC
                        while let presentedController = topController.presentedViewController {
                            topController = presentedController
                        }
                        
                        activityVC.popoverPresentationController?.sourceView = topController.view
                        topController.present(activityVC, animated: true) {
                            print("Share sheet presented successfully")
                        }
                    } else {
                        print("Could not find root view controller")
                    }
                } catch {
                    print("Failed to save temporary PDF: \(error)")
                }
            }
            #endif
        } else {
            print("PDF generation failed")
        }
    }
    
    func shareTravelPlan() {
        #if os(macOS)
        let appURL = URL(string: "https://apps.apple.com/app/id6745529824")!
        let shareText = "\(languageManager.localize("check_out_my_trip_to")) \(travelPlan.location) \(languageManager.localize("created_with_citytailor"))"
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(shareText, forType: .string)
        
        print("Text copied to clipboard: \(shareText)")
        #else
        let appURL = URL(string: "https://apps.apple.com/app/id6745529824")!
        let shareText = "\(languageManager.localize("check_out_my_trip_to")) \(travelPlan.location) \(languageManager.localize("created_with_citytailor"))"
        
        let items: [Any] = [shareText, appURL]
        
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(
                activityItems: items, 
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                var topController = rootVC
                while let presentedController = topController.presentedViewController {
                    topController = presentedController
                }
                
                activityVC.popoverPresentationController?.sourceView = topController.view
                topController.present(activityVC, animated: true) {
                    print("Share sheet for plan presented successfully")
                }
            } else {
                print("Could not find root view controller for sharing")
            }
        }
        #endif
    }
}

struct SafariView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        WebView(url: url)
    }
}

struct TicketableActivityDetailView: View {
    let activity: Activity
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var showGetYourGuideView = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(activity.time)
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text(activity.category)
                            .font(.caption)
                            .padding(5)
                            .background(categoryColor(for: activity.category))
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                    
                    Text(activity.title)
                        .font(.title)
                        .bold()
                    
                    Text(activity.description)
                        .padding(.top, 2)
                    
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(activity.displayAddress)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    HStack(spacing: 12) {
                        if activity.isTicketable {
                            #if os(iOS)
                            Button(action: {
                                if let url = activity.getYourGuideURL {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "ticket.fill")
                                        .foregroundColor(.white)
                                    Text(languageManager.localize("get_tickets"))
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                            #else
                            Button(action: {
                                if let url = activity.getYourGuideURL {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "ticket.fill")
                                        .foregroundColor(.white)
                                    Text(languageManager.localize("get_tickets"))
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                            }
                            #endif
                        }
                        
                        NavigationLink(destination: EmptyDetailView(activity: activity).environmentObject(languageManager)) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.white)
                                Text(languageManager.localize("navigate"))
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle(languageManager.localize("activity"))
            .navigationBarItems(trailing: Button(languageManager.localize("done")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showGetYourGuideView) {
            if let url = activity.getYourGuideURL {
                SafariView(url: url)
            }
        }
    }
    
    func categoryColor(for category: String) -> Color {
        let lowercasedCategory = category.lowercased()
        
        if ["kunst", "art", "arte"].contains(where: lowercasedCategory.contains) {
            return Color.purple
        }
        
        if ["geschichte", "history", "histoire", "historia", "storia"].contains(where: lowercasedCategory.contains) {
            return Color.orange
        }
        
        if ["architektur", "architecture", "arquitectura", "architettura"].contains(where: lowercasedCategory.contains) {
            return Color.blue
        }
        
        if ["gastronomie", "gastronomy", "gastronomía", "gastronomia", "essen", "food", "cuisine"].contains(where: lowercasedCategory.contains) {
            return Color.red
        }
        
        if ["shopping", "einkaufen", "compras", "achats"].contains(where: lowercasedCategory.contains) {
            return Color.pink
        }
        
        if ["nachtleben", "nightlife", "vida nocturna", "vie nocturne", "vita notturna"].contains(where: lowercasedCategory.contains) {
            return Color.indigo
        }
        
        if ["kultur", "culture", "cultura"].contains(where: lowercasedCategory.contains) {
            return Color.teal
        }
        
        if ["sightseeing", "besichtigung", "visites", "visitas", "visite"].contains(where: lowercasedCategory.contains) {
            return Color.green
        }
        
        return Color.gray
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    #if os(iOS)
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    #else
    func makeUIViewController(context: Context) -> NSViewController {
        let controller = NSViewController()
        if let pdfData = items.first as? Data {
            DispatchQueue.main.async {
                let savePanel = NSSavePanel()
                savePanel.nameFieldStringValue = "TravelPlan.pdf"
                savePanel.allowedContentTypes = [UTType.pdf]
                savePanel.canCreateDirectories = true
                
                savePanel.begin { response in
                    if response == .OK, let url = savePanel.url {
                        do {
                            try pdfData.write(to: url)
                            print("PDF successfully saved at: \(url.path)")
                        } catch {
                            print("Failed to save PDF: \(error)")
                        }
                    }
                }
            }
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: NSViewController, context: Context) {}
    #endif
}