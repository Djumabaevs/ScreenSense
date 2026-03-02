import DeviceActivity
import SwiftUI

@available(iOS 17.0, *)
struct ScreenSenseReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .init(rawValue: "totalActivity")
    
    let content: (DeviceActivityResults<DeviceActivityData>) -> TotalActivityView
    
    var body: some DeviceActivityReportScene {
        #if os(iOS)
        content
        #endif
    }
}
