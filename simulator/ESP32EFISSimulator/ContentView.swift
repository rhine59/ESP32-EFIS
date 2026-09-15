import SwiftUI

struct ContentView: View {
    @State private var panel = 0
    @State private var pitch = 3.0
    @State private var roll = 12.0
    @State private var altitude = 2450.0
    @State private var heading = 72.0
    @State private var qnh = 1013.0
    @State private var bug = 60.0
    @State private var auto = false
    @State private var acceptanceSuite = 0 // 0 off, 1 horizon, 2 altimeter, 3 compass
    @State private var attitudeValid = true
    @State private var altitudeValid = true
    @State private var headingValid = true
    @State private var phase = 0.0
    @State private var suiteElapsed = 0.0
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let horizonTests = ["LEVEL","PITCH +10","PITCH -10","PITCH +20","PITCH -20","BANK LEFT 30","BANK RIGHT 30","BANK LEFT 60","BANK RIGHT 60","PITCH +10 BANK R30","ATTITUDE FAIL","RECOVERY LEVEL"]
    private let altimeterTests = ["ALT 0","ALT 500","ALT 1000","ALT 2500","ALT 5000","ALT 9500","ALT 9900","ALT 10000","ALT 10100","ALT 10500","ALT 12500","ALT SWEEP","ALT FAIL","RECOVERY ALT"]
    private let compassTests = ["HDG NORTH","HDG NE","HDG EAST","HDG SE","HDG SOUTH","HDG SW","HDG WEST","HDG NW","HDG 350-010","HDG ROTATE","HEADING FAIL","HDG NORTH"]

    var body: some View {
        GeometryReader { geo in
            let available = geo.size
            let safeWidth = max(0, available.width - 24)
            let safeHeight = max(0, available.height - 24)
            let useSideBySide = safeWidth >= 760 && safeHeight >= 430
            Group { if useSideBySide { sideBySideLayout(width:safeWidth,height:safeHeight) } else { stackedLayout(width:safeWidth,height:safeHeight) } }
                .frame(width:available.width,height:available.height).background(Color(.systemBackground))
        }
        .onReceive(timer) { _ in
            if acceptanceSuite != 0 { stepAcceptance(); return }
            guard auto else { return }
            phase += 0.025
            pitch = sin(phase) * 8
            roll = sin(phase * 0.7) * 28
            altitude = 2450 + sin(phase * 0.25) * 900
            heading = (heading + 0.45).truncatingRemainder(dividingBy:360)
        }
    }

    private var currentTests:[String] { acceptanceSuite == 1 ? horizonTests : (acceptanceSuite == 2 ? altimeterTests : compassTests) }

    private func resetAcceptance(_ suite:Int) {
        acceptanceSuite=suite; suiteElapsed=0; auto=false
        attitudeValid=true; altitudeValid=true; headingValid=true
        pitch=0; roll=0; altitude=2500; heading=0
        if suite==1 { panel=0 }
        if suite==2 { panel=1 }
        if suite==3 { panel=2; bug=60 }
    }

    private func stepAcceptance() {
        suiteElapsed += 0.05
        let tests=currentTests
        let index=Int(suiteElapsed/6.0)%tests.count
        let within=suiteElapsed.truncatingRemainder(dividingBy:6.0)
        attitudeValid=true; altitudeValid=true; headingValid=true
        pitch=0; roll=0; altitude=2500; heading=0
        switch acceptanceSuite {
        case 1:
            panel=0
            switch index {
            case 1: pitch=10
            case 2: pitch = -10
            case 3: pitch=20
            case 4: pitch = -20
            case 5: roll = -30
            case 6: roll=30
            case 7: roll = -60
            case 8: roll=60
            case 9: pitch=10; roll=30
            case 10: attitudeValid=false
            default: break
            }
        case 2:
            panel=1
            switch index {
            case 0: altitude=0
            case 1: altitude=500
            case 2: altitude=1000
            case 3,13: altitude=2500
            case 4: altitude=5000
            case 5: altitude=9500
            case 6: altitude=9900
            case 7: altitude=10000
            case 8: altitude=10100
            case 9: altitude=10500
            case 10: altitude=12500
            case 11:
                let p=Int(within*1000).quotientAndRemainder(dividingBy:10000).remainder
                altitude=Double(p <= 5000 ? p : 10000-p)
            case 12: altitudeValid=false
            default: break
            }
        case 3:
            panel=2; bug=60
            switch index {
            case 0,11: heading=0
            case 1: heading=45
            case 2: heading=90
            case 3: heading=135
            case 4: heading=180
            case 5: heading=225
            case 6: heading=270
            case 7: heading=315
            case 8: heading=(350+within*5).truncatingRemainder(dividingBy:360)
            case 9: heading=(within*60).truncatingRemainder(dividingBy:360)
            case 10: headingValid=false
            default: break
            }
        default: break
        }
    }

    @ViewBuilder private func sideBySideLayout(width:CGFloat,height:CGFloat)->some View {
        let controlWidth=min(max(width*0.36,300),460), instrumentSpace=max(180,width-controlWidth-36), diameter=min(instrumentSpace,height,620)
        HStack(spacing:16){Spacer(minLength:0);instrument.frame(width:diameter,height:diameter).layoutPriority(1);controls.frame(width:controlWidth,maxHeight:.infinity);Spacer(minLength:0)}.padding(12)
    }
    @ViewBuilder private func stackedLayout(width:CGFloat,height:CGFloat)->some View {
        let compactHeight=height<620, desiredDiameter=min(width,compactHeight ? max(220,height*0.58):min(width,height*0.52),560)
        ScrollView{VStack(spacing:12){instrument.frame(width:desiredDiameter,height:desiredDiameter).frame(maxWidth:.infinity);controls.frame(maxWidth:700)}.frame(maxWidth:.infinity).padding(12)}.scrollBounceBehavior(.basedOnSize)
    }
    private var instrument:some View { ZStack { Circle().fill(.black); Group { if panel==0 { HorizonView(pitch:pitch,roll:roll,valid:attitudeValid,altitude:altitudeValid ? altitude:nil,heading:headingValid ? heading:nil) } else if panel==1 { AltimeterView(altitude:altitude,qnh:qnh,valid:altitudeValid) } else { CompassView(heading:heading,bug:bug,valid:headingValid) } }.clipShape(Circle()); Circle().stroke(.gray,lineWidth:5); Text("SIM").font(.headline.bold()).foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,5).background(.red).offset(y:150) }.aspectRatio(1,contentMode:.fit).contentShape(Circle()).onTapGesture{if acceptanceSuite==0{panel=(panel+1)%3}}.accessibilityLabel("ESP32 EFIS instrument display") }

    private var controls:some View { Form {
        Section("ESP32 EFIS bench simulator") {
            ViewThatFits(in:.horizontal){Picker("Panel",selection:$panel){Text("Horizon/PFD").tag(0);Text("Altimeter").tag(1);Text("Compass").tag(2)}.pickerStyle(.segmented);Picker("Panel",selection:$panel){Text("Horizon/PFD").tag(0);Text("Altimeter").tag(1);Text("Compass").tag(2)}.pickerStyle(.menu)}.disabled(acceptanceSuite != 0)
            Toggle("AUTO FLIGHT",isOn:$auto).disabled(acceptanceSuite != 0)
            Picker("QEMU acceptance",selection:$acceptanceSuite){Text("Off").tag(0);Text("Horizon — 12 states").tag(1);Text("Altimeter — 14 states").tag(2);Text("Compass — 12 states").tag(3)}.onChange(of:acceptanceSuite){_,suite in if suite != 0 { resetAcceptance(suite) } else { suiteElapsed=0 } }
            if acceptanceSuite != 0 { let tests=currentTests; let i=Int(suiteElapsed/6.0)%tests.count; Text("Test \(i+1)/\(tests.count): \(tests[i])").font(.caption.monospaced().bold()).foregroundStyle(.orange) }
        }
        Section("Flight data") { valueSlider("Pitch",$pitch,-30...30,"°");valueSlider("Roll",$roll,-60...60,"°");valueSlider("Altitude",$altitude,0...15000," ft");valueSlider("Heading",$heading,0...359,"°") }.disabled(acceptanceSuite != 0)
        Section("Instrument settings") { valueSlider("QNH",$qnh,950...1050," hPa");valueSlider("Heading bug",$bug,0...359,"°") }.disabled(acceptanceSuite != 0)
        Section("Failure injection") { Toggle("Attitude valid",isOn:$attitudeValid);Toggle("Altitude valid",isOn:$altitudeValid);Toggle("Heading valid",isOn:$headingValid) }.disabled(acceptanceSuite != 0)
        Text("SIMULATOR — SYNTHETIC DATA ONLY").font(.caption.bold()).foregroundStyle(.red)
    }.frame(minHeight:330) }
    private func valueSlider(_ name:String,_ value:Binding<Double>,_ range:ClosedRange<Double>,_ suffix:String)->some View { VStack(alignment:.leading,spacing:6){Text("\(name): \(Int(value.wrappedValue))\(suffix)");Slider(value:value,in:range)} }
}
