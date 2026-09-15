import SwiftUI

struct ContentView: View {
    @State private var panel = 0
    @State private var pitch = 3.0
    @State private var roll = 12.0
    @State private var altitude = 2450.0
    @State private var heading = 72.0
    @State private var qnh = 1013.0
    @State private var bug = 90.0
    @State private var auto = false
    @State private var attitudeValid = true
    @State private var altitudeValid = true
    @State private var headingValid = true
    @State private var phase = 0.0
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            Group {
                if landscape { HStack(spacing: 24) { instrument; controls.frame(maxWidth: 420) } }
                else { VStack(spacing: 18) { instrument; controls } }
            }
            .padding().background(Color(.systemBackground))
        }
        .onReceive(timer) { _ in
            guard auto else { return }; phase += 0.025
            pitch = sin(phase) * 8; roll = sin(phase * 0.7) * 28
            altitude = 2450 + sin(phase * 0.25) * 900
            heading = (heading + 0.45).truncatingRemainder(dividingBy: 360)
        }
    }

    private var instrument: some View {
        ZStack {
            Circle().fill(.black)
            Group {
                if panel == 0 { HorizonView(pitch: pitch, roll: roll, valid: attitudeValid, altitude: altitudeValid ? altitude : nil, heading: headingValid ? heading : nil) }
                else if panel == 1 { AltimeterView(altitude: altitude, qnh: qnh, valid: altitudeValid) }
                else { CompassView(heading: heading, bug: bug, valid: headingValid) }
            }.clipShape(Circle())
            Circle().stroke(.gray, lineWidth: 5)
        }
        .aspectRatio(1, contentMode: .fit).frame(maxWidth: 560, maxHeight: 560)
        .onTapGesture { panel = (panel + 1) % 3 }
    }

    private var controls: some View {
        Form {
            Section("ESP32 EFIS bench simulator") {
                Picker("Panel", selection: $panel) { Text("Horizon/PFD").tag(0); Text("Altimeter").tag(1); Text("Compass").tag(2) }.pickerStyle(.segmented)
                Toggle("AUTO FLIGHT", isOn: $auto)
            }
            Section("Flight data") {
                valueSlider("Pitch", $pitch, -30...30, "°")
                valueSlider("Roll", $roll, -60...60, "°")
                valueSlider("Altitude", $altitude, 0...10000, " ft")
                valueSlider("Heading", $heading, 0...359, "°")
            }
            Section("Instrument settings") {
                valueSlider("QNH", $qnh, 950...1050, " hPa")
                valueSlider("Heading bug", $bug, 0...359, "°")
            }
            Section("Failure injection") {
                Toggle("Attitude valid", isOn: $attitudeValid)
                Toggle("Altitude valid", isOn: $altitudeValid)
                Toggle("Heading valid", isOn: $headingValid)
            }
            Text("SIMULATOR — SYNTHETIC DATA ONLY").font(.caption.bold()).foregroundStyle(.red)
        }
    }

    private func valueSlider(_ name: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ suffix: String) -> some View {
        VStack(alignment: .leading) { Text("\(name): \(Int(value.wrappedValue))\(suffix)"); Slider(value: value, in: range) }
    }
}
