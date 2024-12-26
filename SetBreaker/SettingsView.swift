import SwiftUI

struct SettingsView: View {
    @AppStorage("restPeriod") private var restPeriod: Int = 60
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Timer Settings")) {
                    Stepper(value: $restPeriod, in: 15...300, step: 15) {
                        HStack {
                            Text("Rest Period")
                            Spacer()
                            Text("\(restPeriod) seconds")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    Text("SetBreaker helps you maintain your workout rhythm by timing your rest periods while browsing Instagram.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    SettingsView()
} 