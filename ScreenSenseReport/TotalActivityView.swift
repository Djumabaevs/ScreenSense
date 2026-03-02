import DeviceActivity
import SwiftUI

struct TotalActivityView: View {
    var activityReport: String
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Screen Activity")
                .font(.headline)
            
            Text(activityReport)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
