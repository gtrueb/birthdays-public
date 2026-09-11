import SwiftUI

@main
struct BirthdaysApp: App {
    @State private var store = BirthdayStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            BirthdayListView()
                .environment(store)
                .task {
                    #if DEBUG
                    await DebugSeeder.runIfRequested()
                    if CommandLine.arguments.contains("-seedBirthdays"), store.birthdays.isEmpty {
                        store.merge(DebugSeeder.sampleBirthdays())
                    }
                    #endif
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationScheduler.reschedule(store.birthdays)
            }
        }
    }
}
