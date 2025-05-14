import SwiftUI
import CoreData
import UniformTypeIdentifiers
import StoreKit

struct PlanDetailLoader: View {
    let planID: String
    let context: NSManagedObjectContext
    @Environment(\.presentationMode) var presentationMode
    @State private var loadedPlan: SavedTravelPlanViewModel?
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var selectedDay: Int = 1
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var storeManager: StoreManager
    @State private var showPremiumView = false
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Reiseplan wird geladen...")
                            .padding(.top, 20)
                    }
                } else if let plan = loadedPlan {
                    VStack(spacing: 0) {
                        VStack {
                            Text(plan.location)
                                .font(.largeTitle)
                                .bold()
                                .padding(.top)
                            
                            Text("\(DateFormatterUtils.formatDateString(plan.startDate)) \(languageManager.localize("to")) \(DateFormatterUtils.formatDateString(plan.endDate))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom)
                        
                        if let dailyPlans = plan.plan.dailyPlans, !dailyPlans.isEmpty {
                            // Tag-Auswahl
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(dailyPlans) { day in
                                        Button(action: {
                                            selectedDay = day.dayNumber
                                        }) {
                                            VStack(spacing: 2) {
                                                Text("Tag \(day.dayNumber)")
                                                    .font(.caption)
                                                    .fontWeight(selectedDay == day.dayNumber ? .bold : .medium)
                                                    .foregroundColor(selectedDay == day.dayNumber ? .white : .primary)
                                                
                                                Text(formatDateShort(day.date))
                                                    .font(.caption2)
                                                    .foregroundColor(selectedDay == day.dayNumber ? .white.opacity(0.9) : .secondary)
                                            }
                                            .frame(width: 70)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 4)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedDay == day.dayNumber ? Color.blue : Color(.systemGray5))
                                            )
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
                                        selectedDay = firstDay.dayNumber
                                    }
                                }
                            }
                            
                            if let dayPlan = dailyPlans.first(where: { $0.dayNumber == selectedDay }) {
                                List {
                                    ForEach(dayPlan.activities) { activity in
                                        VStack(alignment: .leading, spacing: 5) {
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
                                                .font(.title3)
                                                .bold()
                                                .foregroundColor(.primary)
                                            
                                            Text(activity.description)
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                            
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.red)
                                                Text(activity.displayAddress)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                            .padding(.top, 3)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    
                                    if let recommendations = plan.plan.recommendations {
                                        Section(header: Text("Empfehlungen für diesen Tag")) {
                                            if !recommendations.food.isEmpty {
                                                DisclosureGroup("Essen & Trinken") {
                                                    ForEach(recommendations.food, id: \.self) { food in
                                                        Label(food, systemImage: "fork.knife")
                                                    }
                                                }
                                            }
                                            
                                            if !recommendations.transport.isEmpty {
                                                DisclosureGroup("Transport") {
                                                    ForEach(recommendations.transport, id: \.self) { tip in
                                                        Label(tip, systemImage: "tram.fill")
                                                    }
                                                }
                                            }
                                            
                                            if !recommendations.tips.isEmpty {
                                                DisclosureGroup("Nützliche Tipps") {
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
                                Text("Keine Aktivitäten für diesen Tag gefunden.")
                                Spacer()
                            }
                        } else if let info = plan.plan.info {
                            Spacer()
                            Text(info)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        } else {
                            Spacer()
                            Text("Keine Reiseplan-Daten verfügbar.")
                            Spacer()
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("Reiseplan konnte nicht geladen werden")
                            .font(.headline)
                        
                        if let error = loadError {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        
                        Button("Zurück") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            print("DEBUG: PlanDetailLoader appeared with plan ID: \(planID)")
            loadPlanDetails()
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
                #if os(macOS)
                ShareSheet(items: [pdfData])
                #else
                ShareSheet(items: [pdfData])
                #endif
            }
        }
    }
    
    private func loadPlanDetails() {
        print("DEBUG: Loading plan with ID: \(planID)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard !planID.isEmpty else {
                isLoading = false
                loadError = "Keine Plan-ID verfügbar"
                return
            }
            
            let plans = TravelPlanStore.shared.getTravelPlans(context: context)
            if let matchingPlan = plans.first(where: { $0.id == planID }) {
                print("DEBUG: Plan found for ID \(planID): \(matchingPlan.location)")
                self.loadedPlan = matchingPlan
            } else {
                print("DEBUG: No plan found with ID \(planID)")
                loadError = "Plan nicht gefunden (ID: \(planID))"
            }
            
            isLoading = false
        }
    }
    
    func formatDateShort(_ dateString: String) -> String {
        return DateFormatterUtils.formatDateShort(dateString)
    }
    
    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "kunst": return Color.purple
        case "geschichte": return Color.orange
        case "architektur": return Color.blue
        case "gastronomie": return Color.red
        case "shopping": return Color.pink
        case "nachtleben": return Color.indigo
        case "kultur": return Color.teal
        case "sightseeing": return Color.green
        default: return Color.gray
    }
    }
    
    private func exportPDF() {
        print("Starting PDF export from PlanDetailLoader")
        if let plan = loadedPlan?.plan {
            if let pdfData = PDFGenerator.generatePDF(from: plan, languageManager: languageManager) {
                print("PDF generated successfully, size: \(pdfData.count) bytes")
                
                #if os(macOS)
                let savePanel = NSSavePanel()
                savePanel.nameFieldStringValue = "\(plan.location)_TravelPlan.pdf"
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
                        .appendingPathComponent("\(plan.location)_TravelPlan.pdf")
                    
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
                                
                                let defaults = UserDefaults.standard
                                let pdfExportCount = defaults.integer(forKey: "pdf_export_count") + 1
                                defaults.set(pdfExportCount, forKey: "pdf_export_count")
                                
                                if pdfExportCount >= 2 {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        requestAppReview(in: windowScene)
                                    }
                                }
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
    }
    
    private func shareTravelPlan() {
        guard let plan = loadedPlan else { return }
        
        #if os(macOS)
        let appURL = URL(string: "https://apps.apple.com/app/id6745529824")!
        let shareText = "\(languageManager.localize("check_out_my_trip_to")) \(plan.location) \(languageManager.localize("created_with_citytailor"))"
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(shareText, forType: .string)
        
        print("Text copied to clipboard: \(shareText)")
        #else
        let appURL = URL(string: "https://apps.apple.com/app/id6745529824")!
        let shareText = "\(languageManager.localize("check_out_my_trip_to")) \(plan.location) \(languageManager.localize("created_with_citytailor"))"
        
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
                    
                    let defaults = UserDefaults.standard
                    let shareCount = defaults.integer(forKey: "app_share_count") + 1
                    defaults.set(shareCount, forKey: "app_share_count")
                    
                    if shareCount >= 2 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            requestAppReview(in: windowScene)
                        }
                    }
                }
            } else {
                print("Could not find root view controller for sharing")
            }
        }
        #endif
    }
}

#if os(macOS)
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
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
}
#endif

private func requestAppReview(in windowScene: UIWindowScene) {
    let defaults = UserDefaults.standard
    let lastReviewRequest = defaults.object(forKey: "last_review_request") as? Date
    
    if lastReviewRequest == nil || Date().timeIntervalSince(lastReviewRequest!) > (60*60*24*30) {
        SKStoreReviewController.requestReview(in: windowScene)
        
        defaults.set(Date(), forKey: "last_review_request")
    }
}