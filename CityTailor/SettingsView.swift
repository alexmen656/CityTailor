import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showInterestsView = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Karteneinstellungen")) {
                    Toggle("Verkehr anzeigen", isOn: .constant(false))
                    Toggle("Points of Interest anzeigen", isOn: .constant(true))
                }
                
                Section(header: Text("Erscheinungsbild")) {
                    Picker("Kartenstil", selection: .constant(0)) {
                        Text("Standard").tag(0)
                        Text("Satellit").tag(1)
                        Text("Hybrid").tag(2)
                    }
                    
                    Toggle("Nachtmodus", isOn: .constant(false))
                }
                
                Section(header: Text("Persönliche Einstellungen")) {
                    Button(action: {
                        showInterestsView = true
                    }) {
                        HStack {
                            Text("Interessen")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("Allgemein")) {
                    Toggle("Standort verwenden", isOn: .constant(true))
                    Toggle("Automatische Updates", isOn: .constant(true))
                }
                
                Section {
                    Button(action: {
                        // Hier könnte ein Reset aller Einstellungen erfolgen
                    }) {
                        Text("Auf Standardwerte zurücksetzen")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Einstellungen")
            .navigationBarItems(trailing: Button("Fertig") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showInterestsView) {
                InterestsView()
            }
        }
    }
}