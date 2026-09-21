import SwiftUI

struct ContentView: View {
    @State private var panel = 0
    @State private var acceptanceSuite = 0
    @State private var pitch = 3.0
    @State private var roll = 12.0
    @State private var altitude = 2450.0
    @State private var heading = 72.0
    @State private var qnh = 1013.0
    @State private var bug = 60.0
    @State private var gpsLatitude = 54.0015413
    @State private var gpsLongitude = -2.1407870
    @State private var gpsAccuracy = 0.8
    @State private var auto = false
    @State private var attitudeValid = true
    @State private var altitudeValid = true
    @State private var headingValid = true
    @State private var gpsValid = true
    @State private var gpsStale = false
    @State private var phase = 0.0
    @State private var suiteElapsed = 0.0
    @State private var demoRunning = false
    @State private var demoElapsed = 0.0
    private let timer=Timer.publish(every:0.05,on:.main,in:.common).autoconnect()
    private let horizonTests=["LEVEL","PITCH +10","PITCH -10","PITCH +20","PITCH -20","BANK LEFT 30","BANK RIGHT 30","BANK LEFT 60","BANK RIGHT 60","PITCH +10 BANK R30","ATTITUDE FAIL","RECOVERY LEVEL"]
    private let altimeterTests=["ALT 0","ALT 500","ALT 1000","ALT 2500","ALT 5000","ALT 9500","ALT 9900","ALT 10000","ALT 10100","ALT 10500","ALT 12500","ALT SWEEP","ALT FAIL","RECOVERY ALT"]
    private let compassTests=["HDG NORTH","HDG NE","HDG EAST","HDG SE","HDG SOUTH","HDG SW","HDG WEST","HDG NW","HDG 350-010","HDG ROTATE","HEADING FAIL","HDG NORTH"]
    private let gnssTests=["GPS EXCELLENT","GPS GOOD","GPS FAIR","GPS WEAK","GPS POOR","GPS STALE","GPS NO FIX"]

    var body:some View { GeometryReader{geo in let available=geo.size;let safeWidth=max(0,available.width-24),safeHeight=max(0,available.height-24),side=safeWidth>=760 && safeHeight>=430;Group{if side{sideBySideLayout(width:safeWidth,height:safeHeight)}else{stackedLayout(width:safeWidth,height:safeHeight)}}.frame(width:available.width,height:available.height).background(Color(.systemBackground))}.onReceive(timer){_ in if demoRunning{stepDemo();return};if acceptanceSuite != 0{stepAcceptance();return};guard auto else{return};phase += 0.025;pitch=sin(phase)*8;roll=sin(phase*0.7)*28;altitude=2450+sin(phase*0.25)*900;heading=(heading+0.45).truncatingRemainder(dividingBy:360)} }
    private var currentTests:[String]{switch acceptanceSuite{case 1:return horizonTests;case 2:return altimeterTests;case 3:return compassTests;case 4:return gnssTests;default:return []}}
    private func resetAcceptance(_ suite:Int){acceptanceSuite=suite;suiteElapsed=0;auto=false;attitudeValid=true;altitudeValid=true;headingValid=true;gpsValid=true;gpsStale=false;gpsAccuracy=0.8;pitch=0;roll=0;altitude=2500;heading=0;if suite==1{panel=0};if suite==2{panel=1};if suite==3{panel=2;bug=60};if suite==4{panel=0}}
    private func stepAcceptance(){suiteElapsed += 0.05;let tests=currentTests;guard !tests.isEmpty else{return};let index=Int(suiteElapsed/6.0)%tests.count;let within=suiteElapsed.truncatingRemainder(dividingBy:6.0);attitudeValid=true;altitudeValid=true;headingValid=true;gpsValid=true;gpsStale=false;gpsAccuracy=0.8;pitch=0;roll=0;altitude=2500;heading=0;switch acceptanceSuite{case 1:panel=0;switch index{case 1:pitch=10;case 2:pitch = -10;case 3:pitch=20;case 4:pitch = -20;case 5:roll = -30;case 6:roll=30;case 7:roll = -60;case 8:roll=60;case 9:pitch=10;roll=30;case 10:attitudeValid=false;default:break};case 2:panel=1;switch index{case 0:altitude=0;case 1:altitude=500;case 2:altitude=1000;case 3,13:altitude=2500;case 4:altitude=5000;case 5:altitude=9500;case 6:altitude=9900;case 7:altitude=10000;case 8:altitude=10100;case 9:altitude=10500;case 10:altitude=12500;case 11:let p=Int(within*1000).quotientAndRemainder(dividingBy:10000).remainder;altitude=Double(p<=5000 ? p:10000-p);case 12:altitudeValid=false;default:break};case 3:panel=2;bug=60;switch index{case 0,11:heading=0;case 1:heading=45;case 2:heading=90;case 3:heading=135;case 4:heading=180;case 5:heading=225;case 6:heading=270;case 7:heading=315;case 8:heading=(350+within*5).truncatingRemainder(dividingBy:360);case 9:heading=(within*60).truncatingRemainder(dividingBy:360);case 10:headingValid=false;default:break};case 4:panel=index%2==0 ? 0:2;switch index{case 0:gpsAccuracy=0.8;case 1:gpsAccuracy=2;case 2:gpsAccuracy=6;case 3:gpsAccuracy=18;case 4:gpsAccuracy=45;case 5:gpsStale=true;case 6:gpsValid=false;default:break};default:break}}

    private func startDemo(){demoRunning=true;demoElapsed=0;acceptanceSuite=0;suiteElapsed=0;auto=false;phase=0;panel=0;pitch=0;roll=0;altitude=2500;heading=0;qnh=1013;bug=60;attitudeValid=true;altitudeValid=true;headingValid=true;gpsValid=true;gpsStale=false;gpsAccuracy=0.8}
    private func stopDemo(){demoRunning=false;demoElapsed=0;acceptanceSuite=0;suiteElapsed=0;auto=false}
    private func stepDemo(){
        demoElapsed += 0.05
        let t=demoElapsed
        attitudeValid=true;altitudeValid=true;headingValid=true;gpsValid=true;gpsStale=false;gpsAccuracy=0.8
        if t < 5 { panel=0;pitch=0;roll=0;altitude=2500;heading=72 }
        else if t < 13 { panel=0;let u=t-5;pitch=sin(u*0.9)*15;roll=sin(u*0.65)*40;heading=(72+u*8).truncatingRemainder(dividingBy:360) }
        else if t < 18 { panel=0;attitudeValid=false }
        else if t < 23 { panel=0;pitch=0;roll=0 }
        else if t < 29 { panel=1;altitude=500 }
        else if t < 35 { panel=1;altitude=2500;qnh=1013 }
        else if t < 41 { panel=1;altitude=10500;qnh=1005 }
        else if t < 46 { panel=1;altitudeValid=false }
        else if t < 52 { panel=2;heading=0;bug=60 }
        else if t < 60 { panel=2;heading=((t-52)*45).truncatingRemainder(dividingBy:360);bug=60 }
        else if t < 65 { panel=2;headingValid=false }
        else if t < 71 { panel=0;gpsAccuracy=0.8 }
        else if t < 77 { panel=2;gpsAccuracy=2.0 }
        else if t < 83 { panel=0;gpsAccuracy=6.0 }
        else if t < 89 { panel=2;gpsAccuracy=18.0 }
        else if t < 95 { panel=0;gpsAccuracy=45.0 }
        else if t < 101 { panel=2;gpsStale=true }
        else if t < 107 { panel=0;gpsValid=false }
        else if t < 115 { panel=0;phase += 0.025;pitch=sin(phase)*8;roll=sin(phase*0.7)*28;altitude=2450+sin(phase*0.25)*900;heading=(heading+0.45).truncatingRemainder(dividingBy:360) }
        else if t < 187 { if acceptanceSuite != 1{resetAcceptance(1)};stepAcceptance() }
        else if t < 271 { if acceptanceSuite != 2{resetAcceptance(2)};stepAcceptance() }
        else if t < 343 { if acceptanceSuite != 3{resetAcceptance(3)};stepAcceptance() }
        else if t < 385 { if acceptanceSuite != 4{resetAcceptance(4)};stepAcceptance() }
        else { stopDemo();panel=0;pitch=0;roll=0;altitude=2500;heading=72;gpsValid=true;gpsStale=false;gpsAccuracy=0.8 }
    }
    private var demoLabel:String { let t=demoElapsed;if t<5{return "Horizon overview"};if t<13{return "Pitch and roll"};if t<18{return "Attitude failure"};if t<23{return "Attitude recovery"};if t<29{return "Altimeter 500 ft"};if t<35{return "Altimeter / QNH"};if t<41{return ">10,000 ft hatching"};if t<46{return "Altitude failure"};if t<52{return "Compass / heading bug"};if t<60{return "Heading rotation"};if t<65{return "Heading failure"};if t<71{return "GNSS excellent"};if t<77{return "GNSS good"};if t<83{return "GNSS fair"};if t<89{return "GNSS weak"};if t<95{return "GNSS poor"};if t<101{return "GNSS stale"};if t<107{return "GNSS no fix"};if t<115{return "Auto flight"};if t<187{return "Horizon acceptance suite"};if t<271{return "Altimeter acceptance suite"};if t<343{return "Compass acceptance suite"};return "GNSS acceptance suite" }

    @ViewBuilder private func sideBySideLayout(width:CGFloat,height:CGFloat)->some View{let cw=min(max(width*0.36,300),460),space=max(180,width-cw-36),diameter=min(space,height,620);HStack(spacing:16){Spacer(minLength:0);instrument.frame(width:diameter,height:diameter).layoutPriority(1);controls.frame(width:cw).frame(maxHeight:.infinity);Spacer(minLength:0)}.padding(12)}
    @ViewBuilder private func stackedLayout(width:CGFloat,height:CGFloat)->some View{let compact=height<620,diameter=min(width,compact ? max(220,height*0.58):min(width,height*0.52),560);ScrollView{VStack(spacing:12){instrument.frame(width:diameter,height:diameter).frame(maxWidth:.infinity);controls.frame(maxWidth:700)}.frame(maxWidth:.infinity).padding(12)}.scrollBounceBehavior(.basedOnSize)}
    private var instrument:some View{ZStack{Circle().fill(.black);Group{if panel==0{HorizonView(pitch:pitch,roll:roll,valid:attitudeValid,altitude:altitudeValid ? altitude:nil,heading:headingValid ? heading:nil,qnh:qnh,gpsLatitude:gpsLatitude,gpsLongitude:gpsLongitude,gpsAccuracy:gpsAccuracy,gpsValid:gpsValid,gpsStale:gpsStale)}else if panel==1{AltimeterView(altitude:altitude,qnh:qnh,valid:altitudeValid)}else{CompassView(heading:heading,bug:bug,valid:headingValid,gpsLatitude:gpsLatitude,gpsLongitude:gpsLongitude,gpsAccuracy:gpsAccuracy,gpsValid:gpsValid,gpsStale:gpsStale)}}.clipShape(Circle());Circle().stroke(.gray,lineWidth:5);GeometryReader { ig in let d=min(ig.size.width,ig.size.height);Text("SIM").font(.system(size:d * 0.045,weight:.bold)).foregroundStyle(.white).padding(.horizontal,d * 0.025).padding(.vertical,d * 0.012).background(.red).position(x:d * 0.5,y:d * 0.90) }}.aspectRatio(1,contentMode:.fit).contentShape(Circle()).onTapGesture{if acceptanceSuite==0 && !demoRunning{panel=(panel+1)%3}}.accessibilityLabel("ESP32 EFIS instrument display")}
    private var controls:some View{Form{Section("ESP32 EFIS bench simulator"){Button(demoRunning ? "STOP FULL DEMONSTRATION" : "RUN FULL DEMONSTRATION"){if demoRunning{stopDemo()}else{startDemo()}}.buttonStyle(.borderedProminent);if demoRunning{Text("DEMO \(Int(demoElapsed))s / 385s — \(demoLabel)").font(.caption.monospaced().bold()).foregroundStyle(.orange)};ViewThatFits(in:.horizontal){Picker("Panel",selection:$panel){Text("Horizon/PFD").tag(0);Text("Altimeter").tag(1);Text("Compass").tag(2)}.pickerStyle(.segmented);Picker("Panel",selection:$panel){Text("Horizon/PFD").tag(0);Text("Altimeter").tag(1);Text("Compass").tag(2)}.pickerStyle(.menu)}.disabled(acceptanceSuite != 0 || demoRunning);Toggle("AUTO FLIGHT",isOn:$auto).disabled(acceptanceSuite != 0 || demoRunning);Picker("QEMU acceptance",selection:$acceptanceSuite){Text("Off").tag(0);Text("Horizon — 12 states").tag(1);Text("Altimeter — 14 states").tag(2);Text("Compass — 12 states").tag(3);Text("GNSS — 7 states").tag(4)}.disabled(demoRunning).onChange(of:acceptanceSuite){_,suite in if suite != 0{resetAcceptance(suite)}else{suiteElapsed=0}};if acceptanceSuite != 0 && !demoRunning{let tests=currentTests;let i=Int(suiteElapsed/6.0)%tests.count;Text("Test \(i+1)/\(tests.count): \(tests[i])").font(.caption.monospaced().bold()).foregroundStyle(.orange)}};Section("Flight data"){valueSlider("Pitch",$pitch,-30...30,"°");valueSlider("Roll",$roll,-60...60,"°");valueSlider("Altitude",$altitude,0...15000," ft");valueSlider("Heading",$heading,0...359,"°")}.disabled(acceptanceSuite != 0 || demoRunning);Section("GNSS synthetic data"){Text(String(format:"Lat %.5f  Lon %.5f",gpsLatitude,gpsLongitude)).font(.caption.monospaced());valueSlider("Horizontal accuracy",$gpsAccuracy,0...60," m");Toggle("GNSS fix valid",isOn:$gpsValid);Toggle("GNSS stale",isOn:$gpsStale)}.disabled(acceptanceSuite != 0 || demoRunning);Section("Instrument settings"){valueSlider("QNH",$qnh,950...1050," hPa");valueSlider("Heading bug",$bug,0...359,"°")}.disabled(acceptanceSuite != 0 || demoRunning);Section("Failure injection"){Toggle("Attitude valid",isOn:$attitudeValid);Toggle("Altitude valid",isOn:$altitudeValid);Toggle("Heading valid",isOn:$headingValid)}.disabled(acceptanceSuite != 0 || demoRunning);Text("SIMULATOR — SYNTHETIC DATA ONLY").font(.caption.bold()).foregroundStyle(.red)}.frame(minHeight:330)}
    private func valueSlider(_ name:String,_ value:Binding<Double>,_ range:ClosedRange<Double>,_ suffix:String)->some View{VStack(alignment:.leading,spacing:6){Text("\(name): \(String(format:"%.1f",value.wrappedValue))\(suffix)");Slider(value:value,in:range)}}
}
