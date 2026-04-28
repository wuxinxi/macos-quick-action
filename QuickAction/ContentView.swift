import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cursorarrow.and.square.on.square.dashed")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
            
            Text("Super Right Click")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enhance your macOS Finder with powerful context menu actions.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("How to enable:")
                    .font(.headline)
                
                HStack(alignment: .top) {
                    Text("1.")
                    Text("Click the button below to open **Privacy & Security**")
                }
                HStack(alignment: .top) {
                    Text("2.")
                    Text("Scroll down to **Others** and click **Extensions**")
                }
                HStack(alignment: .top) {
                    Text("3.")
                    Text("Click **Added extensions** and enable **FinderSyncExt**")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 40)
            
            Button(action: {
                openExtensionSettings()
            }) {
                Text("Open Extension Settings")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(width: 450, height: 450)
    }
    
    private func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preferences.extensions") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
