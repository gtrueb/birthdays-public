import SwiftUI
import UIKit

/// Month, day and year wheels in one picker, like the birthday field in Contacts.
/// A year of 0 means "no year" and shows as dashes.
struct BirthdayWheelPicker: UIViewRepresentable {
    @Binding var month: Int
    @Binding var day: Int
    @Binding var year: Int

    /// Dashes first, then the years counting down, so the wheel reads in one direction.
    private var years: [Int] { [0] + Array((1900...Calendar.current.component(.year, from: .now)).reversed()) }

    func makeUIView(context: Context) -> UIView {
        // A container so the picker fills the row instead of its 320pt intrinsic width.
        let container = UIView()
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        container.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            picker.topAnchor.constraint(equalTo: container.topAnchor),
            picker.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        context.coordinator.picker = picker
        return container
    }

    func updateUIView(_ container: UIView, context: Context) {
        context.coordinator.parent = self
        guard let picker = context.coordinator.picker else { return }
        picker.reloadComponent(1)
        let yearRow = years.firstIndex(of: year) ?? 0
        if picker.selectedRow(inComponent: 0) != month - 1 { picker.selectRow(month - 1, inComponent: 0, animated: false) }
        if picker.selectedRow(inComponent: 1) != day - 1 { picker.selectRow(day - 1, inComponent: 1, animated: false) }
        if picker.selectedRow(inComponent: 2) != yearRow { picker.selectRow(yearRow, inComponent: 2, animated: false) }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    var daysInMonth: Int {
        let cal = Calendar.current
        let comps = DateComponents(year: year == 0 ? 2024 : year, month: month)
        guard let date = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: BirthdayWheelPicker
        weak var picker: UIPickerView?
        init(_ parent: BirthdayWheelPicker) { self.parent = parent }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 3 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            switch component {
            case 0: return 12
            case 1: return parent.daysInMonth
            default: return parent.years.count
            }
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            let total = pickerView.bounds.width - 24
            switch component {
            case 0: return total * 0.48
            case 1: return total * 0.20
            default: return total * 0.32
            }
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            switch component {
            case 0: return Calendar.current.monthSymbols[row]
            case 1: return String(row + 1)
            default: return parent.years[row] == 0 ? "----" : String(parent.years[row])
            }
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            switch component {
            case 0: parent.month = row + 1
            case 1: parent.day = row + 1
            default: parent.year = parent.years[row]
            }
            let max = parent.daysInMonth
            if parent.day > max {
                parent.day = max
                pickerView.reloadComponent(1)
                pickerView.selectRow(max - 1, inComponent: 1, animated: true)
            } else if component != 1 {
                pickerView.reloadComponent(1)
            }
        }
    }
}
