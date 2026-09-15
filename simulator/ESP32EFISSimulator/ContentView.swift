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
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let available = geo.size
            let safeWidth = max(0, available.width - 24)
            let safeHeight = max(0, available.height - 24)
            let useSideBySide = safeWidth >= 760 && safeHeight >= 430

            Group {
                if useSideBySide {
                    sideBySideLayout(width: safeWidth, height: safeHeight)
                } else {
                    stackedLayout(width: safeWidth, height: safeHeight)
                }
            }
            .frame(width: available.width, height: available.height)
            .background(Color(.systemBackground))
        }
        .onReceive(timer) { _ in
            guard auto else { return }
            phase += 0.025
            pitch = sin(phase) * 8
            roll = sin(phase * 0.7) * 28
            altitude = 2450 + sin(phase * 0.25) * 900
            heading = (heading + 0.45).truncatingRemainder(dividingBy: 360)
        }
    }

    @ViewBuilder
    private func sideBySideLayout(width: CGFloat, height: CGFloat) -> some View {
        let controlWidth = min(max(width * 0.36, 300), 460)
        let instrumentSpace = max(180, width - controlWidth - 36)
        let diameter = min(instrumentSpace, height, 620)

        HStack(spacing: 16) {
            Spacer(minLength: 0)
            instrument
                .frame(width: diameter, height: diameter)
                .layoutPriority(1)
            controls
                .frame(width: controlWidth, maxHeight: .infinity)
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    @ViewBuilder
    private func stackedLayout(width: CGFloat, height: CGFloat) -> some View {
        // Reserve enough room for a usable controls pane. On very short landscape
        // iPhones the whole screen scrolls, rather than clipping either instrument or controls.
        let compactHeight = height < 620
        let desiredDiameter = min(width, compactHeight ? max(220, height * 0.58) : min(width, height * 0.52), 560)

        ScrollView {
            VStack(spacing: 12) {
                instrument
                    .frame(width: desiredDiameter, height: desiredDiameter)
                    .frame(maxWidth: .infinity)
                controls
                    .frame(maxWidth: 700)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var instrument: some View {
        ZStack {
            Circle().fill(.black)
            Group {
                if panel == 0 {
                    HorizonView(pitch: pitch, roll: roll, valid: attitudeValid,
                                altitude: altitudeValid ? altitude : nil,
                                heading: headingValid ? heading : nil)
                } else if panel == 1 {
                    AltimeterView(altitude: altitude, qnh: qnh, valid: altitudeValid)
                } else {
                    CompassView(heading: heading, bug: bug, valid: headingValid)
                }
            }
            .clipShape(Circle())
            Circle().stroke(.gray, lineWidth: 5)
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Circle())
        .onTapGesture { panel = (panel + 1) % 3 }
        .accessibilityLabel("ESP32 EFIS instrument display")
    }

    private var controls: some View {
        Form {
            Section("ESP32 EFIS bench simulator") {
                ViewThatFits(in: .horizontal) {
                    Picker("Panel", selection: $panel) {
                        Text("Horizon/PFD").tag(0)
                        Text("Altimeter").tag(1)
                        Text("Compass").tag(2)
                    }
                    .pickerStyle(.segmented)

                    Picker("Panel", selection: $panel) {
                        Text("Horizon/PFD").tag(0)
                        Text("Altimeter").tag(1)
                        Text("Compass").tag(2)
                    }
                    .pickerStyle(.menu)
                }
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
            Text("SIMULATOR — SYNTHETIC DATA ONLY")
                .font(.caption.bold())
                .foregroundStyle(.red)
        }
        .frame(minHeight: 330)
    }

    private func valueSlider(_ name: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(name): \(Int(value.wrappedValue))\(suffix)")
            Slider(value: value, in: range)
        }
    }
}
