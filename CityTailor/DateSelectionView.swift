import SwiftUI

struct DateSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    let locationName: String
    
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3 * 24 * 60 * 60)
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @State private var travelPlan: TravelPlan?
    @State private var showTravelPlan = false
    
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
                        sendDataToBackend()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("An Backend senden")
                                .frame(maxWidth: .infinity)
                                .bold()
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Reiseplanung")
            .navigationBarItems(trailing: Button("Schließen") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Backend-Benachrichtigung"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showTravelPlan) {
                if let plan = travelPlan {
                    TravelPlanView(travelPlan: plan)
                }
            }
        }
    }
    
    func sendDataToBackend() {
        isLoading = true
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let tripData: [String: Any] = [
            "location": locationName,
            "startDate": dateFormatter.string(from: startDate),
            "endDate": dateFormatter.string(from: endDate),
            "durationInDays": tripLengthInDays
        ]
        
        guard let url = URL(string: "http://localhost:4040/api/trips") else {
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
                                self.showTravelPlan = true
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