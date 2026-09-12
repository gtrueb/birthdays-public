# Birthdays

A small birthday calendar for iPhone that looks and feels like an Apple app.

- Upcoming birthdays grouped by Today, Next 7 Days, and month
- Import from Contacts, from Calendar, or from pasted text ("Anna Meier, 14 September 1990")
- Detail page with message / call / FaceTime / mail, notes, share
- Notifications on the day, 1 day and 1 week before, with a per-person time
- Home Screen widget (small and medium)

Built with SwiftUI, iOS 17+. No accounts, no servers, data stays on the phone.

## Put it on your iPhone

1. Generate the Xcode project (once, or after editing `project.yml`):

   ```bash
   brew install xcodegen   # if you don't have it
   xcodegen generate
   open Birthdays.xcodeproj
   ```

2. In Xcode: **Xcode > Settings > Accounts**, sign in with your Apple ID.
3. Select the **Birthdays** target > **Signing & Capabilities**. Tick *Automatically manage signing* and pick your team. Do the same for the **BirthdaysWidget** target.
   If Xcode complains about the bundle identifier, change `com.giantrub` in `project.yml` to something of your own and run `xcodegen generate` again.
4. Plug in the iPhone, choose it as the run destination, press **Run**.
5. On the phone, the first time: **Settings > General > VPN & Device Management**, trust your developer certificate.

A free Apple ID works. The app then has to be reinstalled every 7 days; a paid developer account removes that limit.

## Development

- `scripts/build.sh` – builds for the simulator
- `scripts/sim.sh boot|install|launch|shot` – runs the app on the "Gauntlet iPhone" simulator
- Launch arguments for testing (Debug builds only): `-seedBirthdays`, `-seedContacts`, `-resetBirthdays`, `-screen detail|add|settings|contacts|calendar|text`
- `progress/` holds the design gauntlet history: every round's screenshots and the live page generator.
