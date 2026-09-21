import SwiftUI

enum GNSSQuality: String, CaseIterable {
 case invalid = "NO FIX", poor = "POOR", weak = "WEAK", fair = "FAIR", good = "GOOD", excellent = "EXCELLENT"
 static func classify(accuracy: Double, valid: Bool, stale: Bool) -> GNSSQuality {
 guard valid, !stale, accuracy >= 0 else { return .invalid }
 if accuracy <= 1 { return .excellent }; if accuracy <= 3 { return .good }; if accuracy <= 10 { return .fair }; if accuracy <= 30 { return .weak }; return .poor
 }
 var colour: Color { switch self { case .excellent,.good: return .green; case .fair,.weak: return .yellow; case .poor,.invalid: return .red } }
}

struct GNSSPositionView: View {
 let latitude, longitude, accuracy: Double; let valid, stale: Bool
 var body: some View {
  let q=GNSSQuality.classify(accuracy:accuracy,valid:valid,stale:stale)
  Text(q == .invalid ? (stale ? "GPS STALE" : "GPS NO FIX") : String(format:"%0.5f  %0.5f",latitude,longitude))
   .font(.system(size:15,weight:.bold,design:.monospaced))
   .foregroundStyle(q.colour)
   .padding(.horizontal,6).padding(.vertical,4)
   .background(.black.opacity(0.82))
 }
}

struct HorizonView: View {
    let pitch, roll: Double
    let valid: Bool
    let altitude, heading: Double?
    let qnh: Double
    let gpsLatitude, gpsLongitude, gpsAccuracy: Double
    let gpsValid, gpsStale: Bool
    private let bankMarks = [10,20,30,45,60]
    private let pitchMarks = [-20,-15,-10,-5,5,10,15,20]

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            ZStack {
                attitudeSphere(s)
                bankScale(s)
                aircraftSymbol(s)
                dataOverlays(s)
                if !valid { invalid(s, "ATT FAIL") }
            }
            .frame(width: s, height: s)
            .clipShape(Circle())
        }
    }

    @ViewBuilder private func attitudeSphere(_ s: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(.blue).frame(width:s * 1.8,height:s * 0.9).offset(y:-s * 0.45)
            Rectangle().fill(.brown).frame(width:s * 1.8,height:s * 0.9).offset(y:s * 0.45)
            Rectangle().fill(.white).frame(width:s * 1.8,height:3)
            ForEach(pitchMarks,id:\.self) { p in
                let major = abs(p) % 10 == 0
                HStack(spacing: major ? s * 0.08 : s * 0.055) {
                    Rectangle().frame(width:major ? s * 0.15:s * 0.075,height:major ? 3:2)
                    Rectangle().frame(width:major ? s * 0.15:s * 0.075,height:major ? 3:2)
                }
                .foregroundStyle(.white)
                .overlay {
                    if major {
                        HStack {
                            Text(String(p)).frame(width:s * 0.08,alignment:.trailing)
                            Spacer()
                            Text(String(p)).frame(width:s * 0.08,alignment:.leading)
                        }
                        .font(.system(size:s * 0.032,weight:.bold,design:.rounded))
                        .foregroundStyle(.white)
                        .frame(width:s * 0.48)
                    }
                }
                .offset(y:CGFloat(-p) * s / 40)
            }
        }
        .frame(width:s * 1.8,height:s * 1.8)
        .offset(y:pitch * s / 40)
        .rotationEffect(.degrees(-roll))
    }

    @ViewBuilder private func bankScale(_ s: CGFloat) -> some View {
        ForEach(bankMarks,id:\.self) { d in
            let major=d==30 || d==60
            Capsule().fill(.white).frame(width:major ? 4:3,height:major ? s * 0.052:s * 0.04).offset(y:-s * 0.395).rotationEffect(.degrees(Double(d)))
            Capsule().fill(.white).frame(width:major ? 4:3,height:major ? s * 0.052:s * 0.04).offset(y:-s * 0.395).rotationEffect(.degrees(Double(-d)))
        }
        Capsule().fill(.white).frame(width:4,height:s * 0.062).offset(y:-s * 0.39)
        Text("0°").font(.system(size:s * 0.027,weight:.bold)).foregroundStyle(.white).offset(y:-s * 0.455)
        ForEach(bankMarks,id:\.self) { d in
            Text(String(format:"%d°",d)).font(.system(size:s * 0.026,weight:.bold)).foregroundStyle(.white)
                .offset(y:-s * 0.455).rotationEffect(.degrees(Double(d))).rotationEffect(.degrees(Double(-d)))
            Text(String(format:"-%d°",d)).font(.system(size:s * 0.026,weight:.bold)).foregroundStyle(.white)
                .offset(y:-s * 0.455).rotationEffect(.degrees(Double(-d))).rotationEffect(.degrees(Double(d)))
        }
        Path { p in
            p.move(to:CGPoint(x:s * 0.5,y:s * 0.14))
            p.addLine(to:CGPoint(x:s * 0.475,y:s * 0.19))
            p.addLine(to:CGPoint(x:s * 0.525,y:s * 0.19))
            p.closeSubpath()
        }.stroke(.black,lineWidth:7).frame(width:s,height:s).rotationEffect(.degrees(roll))
        Path { p in
            p.move(to:CGPoint(x:s * 0.5,y:s * 0.14))
            p.addLine(to:CGPoint(x:s * 0.475,y:s * 0.19))
            p.addLine(to:CGPoint(x:s * 0.525,y:s * 0.19))
            p.closeSubpath()
        }.stroke(.white,lineWidth:3).frame(width:s,height:s).rotationEffect(.degrees(roll))
    }

    @ViewBuilder private func aircraftSymbol(_ s: CGFloat) -> some View {
        Path { p in
            p.move(to:CGPoint(x:s * 0.29,y:s * 0.5)); p.addLine(to:CGPoint(x:s * 0.44,y:s * 0.5))
            p.addLine(to:CGPoint(x:s * 0.475,y:s * 0.535)); p.addLine(to:CGPoint(x:s * 0.525,y:s * 0.535))
            p.addLine(to:CGPoint(x:s * 0.56,y:s * 0.5)); p.addLine(to:CGPoint(x:s * 0.71,y:s * 0.5))
        }.stroke(.black, style: StrokeStyle(lineWidth:10, lineCap:.square, lineJoin:.miter)).frame(width:s,height:s)
        Path { p in
            p.move(to:CGPoint(x:s * 0.29,y:s * 0.5)); p.addLine(to:CGPoint(x:s * 0.44,y:s * 0.5))
            p.addLine(to:CGPoint(x:s * 0.475,y:s * 0.535)); p.addLine(to:CGPoint(x:s * 0.525,y:s * 0.535))
            p.addLine(to:CGPoint(x:s * 0.56,y:s * 0.5)); p.addLine(to:CGPoint(x:s * 0.71,y:s * 0.5))
        }.stroke(.yellow, style: StrokeStyle(lineWidth:5, lineCap:.square, lineJoin:.miter)).frame(width:s,height:s)
    }

    @ViewBuilder private func dataOverlays(_ s: CGFloat) -> some View {
        if let h=heading {
            Text(String(format:"%03.0f",h == 0 ? 360:h))
                .font(.system(size:s * 0.055,weight:.bold,design:.monospaced))
                .foregroundStyle(.white).position(x:s * 0.5,y:s * 0.085)
        }
        if let a=altitude {
            VStack(spacing:2) {
                Text(String(format:"%0.0f",a))
                    .font(.system(size:s * 0.05,weight:.bold,design:.monospaced))
                    .padding(.horizontal,8).padding(.vertical,5)
                    .frame(minWidth:s * 0.22)
                    .background(.black.opacity(0.88))
                    .overlay(Rectangle().stroke(.white,lineWidth:1))
                Text(String(format:"%0.0f",qnh))
                    .font(.system(size:s * 0.035,weight:.bold,design:.monospaced))
                    .padding(.horizontal,8).padding(.vertical,4)
                    .frame(minWidth:s * 0.22)
                    .background(.black.opacity(0.88))
                    .overlay(Rectangle().stroke(.white,lineWidth:1))
            }
            .foregroundStyle(.white).position(x:s * 0.80,y:s * 0.34)
        }
        GNSSPositionView(latitude:gpsLatitude,longitude:gpsLongitude,accuracy:gpsAccuracy,valid:gpsValid,stale:gpsStale)
            .position(x:s * 0.5,y:s * 0.79)
    }
}

struct AltimeterView: View {
 let altitude,qnh: Double; let valid: Bool
 var body: some View { GeometryReader { g in let s=g.size.width;let a=max(0,altitude); ZStack { Circle().fill(.black);Circle().stroke(.gray,lineWidth:s * 0.03).padding(s * 0.015);Circle().stroke(.white,lineWidth:3).padding(s * 0.045);ForEach(0..<50,id:\.self){i in Capsule().fill(.white).frame(width:i%5==0 ? 3:1,height:i%5==0 ? s * 0.058:s * 0.026).offset(y:-s * 0.405).rotationEffect(.degrees(Double(i) * 7.2))};ForEach(0..<10,id:\.self){i in Text("\(i)").font(.system(size:s * 0.065,weight:.bold,design:.rounded)).foregroundStyle(.white).offset(y:-s * 0.33).rotationEffect(.degrees(Double(i) * 36)).rotationEffect(.degrees(-Double(i) * 36))};Text("ALT").font(.system(size:s * 0.045,weight:.bold,design:.monospaced)).foregroundStyle(.white).offset(y:-s * 0.18);Text("FEET").font(.system(size:s * 0.027,weight:.bold,design:.monospaced)).foregroundStyle(.gray).offset(y:-s * 0.125);kollsman(s);if valid { if a>10000{altitudeHatching(s,altitude:a)};hand(s,a.truncatingRemainder(dividingBy:1000) * 0.36,s * 0.30,3);hand(s,a.truncatingRemainder(dividingBy:10000) * 0.036,s * 0.22,5);hand(s,a.truncatingRemainder(dividingBy:100000) * 0.0036,s * 0.145,7);Circle().fill(.white).frame(width:s * 0.03,height:s * 0.03);Text("\(Int(a))").font(.system(size:s * 0.052,weight:.bold,design:.monospaced)).foregroundStyle(.green).padding(.horizontal,s * 0.025).padding(.vertical,s * 0.012).background(.black).overlay(Rectangle().stroke(.white,lineWidth:1)).offset(y:s * 0.16)}else{invalid(s,"ALT FAIL")} } }}
 private func hand(_ s:CGFloat,_ deg:Double,_ length:CGFloat,_ width:CGFloat)->some View { Rectangle().fill(.white).frame(width:width,height:length).offset(y:-length/2).rotationEffect(.degrees(deg)) }
 @ViewBuilder private func kollsman(_ s:CGFloat)->some View { let degreesPerHpa=2.0,halfWindow=8.0;let pressures=Array(950...1050).filter{abs((Double($0)-qnh) * degreesPerHpa)<=halfWindow};ZStack{AnnularSector(startDegrees:-halfWindow,endDegrees:halfWindow,innerFraction:0.61).fill(.black).frame(width:s * 0.85,height:s * 0.85);ForEach(pressures,id:\.self){p in let delta=(Double(p)-qnh) * degreesPerHpa;let major=p%5==0;Capsule().fill(.white).frame(width:major ? 2:1,height:major ? s * 0.055:s * 0.042).offset(y:-s * 0.383).rotationEffect(.degrees(90+delta));if major{Text("\(p)").font(.system(size:s * 0.025,weight:.bold,design:.monospaced)).foregroundStyle(.white).offset(x:s * 0.315).rotationEffect(.degrees(delta)).rotationEffect(.degrees(-delta))}};let stdDelta=(1013.25-qnh) * degreesPerHpa;if abs(stdDelta)<=halfWindow{Capsule().fill(.white).frame(width:5,height:s * 0.065).offset(y:-s * 0.375).rotationEffect(.degrees(90+stdDelta))};Capsule().fill(.white).frame(width:3,height:s * 0.075).offset(y:-s * 0.383).rotationEffect(.degrees(90))} }
 @ViewBuilder private func altitudeHatching(_ s:CGFloat,altitude:Double)->some View {let fraction=min(1,max(0,(altitude-10000)/1000)),sweep=60.0 * fraction;ZStack{ForEach(-8...8,id:\.self){i in Rectangle().fill(.white).frame(width:2,height:s * 0.20).rotationEffect(.degrees(45)).offset(x:CGFloat(i) * s * 0.022)}}.frame(width:s * 0.31,height:s * 0.31).clipShape(AnnularSector(startDegrees:240,endDegrees:240+sweep,innerFraction:0.70)).offset(x:-s * 0.285)}
}

private struct AnnularSector: Shape { let startDegrees:Double;let endDegrees:Double;let innerFraction:CGFloat;func path(in rect:CGRect)->Path{let c=CGPoint(x:rect.midX,y:rect.midY),r=min(rect.width,rect.height)/2,ir=r * innerFraction;var p=Path();p.addArc(center:c,radius:r,startAngle:.degrees(startDegrees),endAngle:.degrees(endDegrees),clockwise:false);p.addArc(center:c,radius:ir,startAngle:.degrees(endDegrees),endAngle:.degrees(startDegrees),clockwise:true);p.closeSubpath();return p} }

struct CompassView: View {
 let heading,bug: Double; let valid: Bool
 let gpsLatitude, gpsLongitude, gpsAccuracy: Double; let gpsValid, gpsStale: Bool
 private func relative(_ selected:Double,_ heading:Double)->Double{var d=(selected-heading).truncatingRemainder(dividingBy:360);if d<0{d+=360};return d}
 var body: some View { GeometryReader { g in let s=g.size.width;let hdg=((heading.truncatingRemainder(dividingBy:360))+360).truncatingRemainder(dividingBy:360);ZStack{Circle().fill(.black);Circle().stroke(.gray,lineWidth:s * 0.03).padding(s * 0.015);Circle().stroke(.white,lineWidth:3).padding(s * 0.045);ZStack{ForEach(0..<72,id:\.self){i in Capsule().fill(.white).frame(width:i%6==0 ? 3:1,height:i%6==0 ? s * 0.058:(i%2==0 ? s * 0.038:s * 0.022)).offset(y:-s * 0.405).rotationEffect(.degrees(Double(i) * 5))};ForEach(Array([(0,"N"),(90,"E"),(180,"S"),(270,"W")].enumerated()), id:\.offset){_,item in let (d,t)=item; Text(t).font(.system(size:s * 0.065,weight:.bold,design:.rounded)).foregroundStyle(.white).offset(y:-s * 0.32).rotationEffect(.degrees(Double(d))).rotationEffect(.degrees(-Double(d)))}}.rotationEffect(.degrees(-hdg));Path{p in p.move(to:CGPoint(x:s * 0.5,y:s * 0.038));p.addLine(to:CGPoint(x:s * 0.472,y:s * 0.10));p.addLine(to:CGPoint(x:s * 0.528,y:s * 0.10));p.closeSubpath()}.stroke(.yellow,lineWidth:3);Path{p in p.move(to:CGPoint(x:s * 0.5,y:s * 0.075));p.addLine(to:CGPoint(x:s * 0.475,y:s * 0.125));p.addLine(to:CGPoint(x:s * 0.525,y:s * 0.125));p.closeSubpath()}.stroke(.yellow,lineWidth:4).rotationEffect(.degrees(relative(bug,hdg)));Path{p in p.move(to:CGPoint(x:s * 0.34,y:s * 0.51));p.addLine(to:CGPoint(x:s * 0.66,y:s * 0.51));p.move(to:CGPoint(x:s * 0.5,y:s * 0.37));p.addLine(to:CGPoint(x:s * 0.5,y:s * 0.64));p.move(to:CGPoint(x:s * 0.43,y:s * 0.64));p.addLine(to:CGPoint(x:s * 0.5,y:s * 0.585));p.addLine(to:CGPoint(x:s * 0.57,y:s * 0.64))}.stroke(.yellow,lineWidth:5);Text(String(format:"%03.0f",hdg)).font(.system(size:s * 0.075,weight:.bold,design:.monospaced)).foregroundStyle(.green).padding(.horizontal,s * 0.025).padding(.vertical,s * 0.012).background(.black).overlay(Rectangle().stroke(.white,lineWidth:1)).offset(y:s * 0.18);GNSSPositionView(latitude:gpsLatitude,longitude:gpsLongitude,accuracy:gpsAccuracy,valid:gpsValid,stale:gpsStale).position(x:s/2,y:s * 0.78);if !valid{invalid(s,"HDG FAIL")}} }}
}

@ViewBuilder private func invalid(_ s:CGFloat,_ text:String)->some View { ZStack { Path{p in p.move(to:CGPoint(x:s * 0.22,y:s * 0.22));p.addLine(to:CGPoint(x:s * 0.78,y:s * 0.78));p.move(to:CGPoint(x:s * 0.78,y:s * 0.22));p.addLine(to:CGPoint(x:s * 0.22,y:s * 0.78))}.stroke(.red,lineWidth:10);Text(text).font(.headline.bold()).foregroundStyle(.red).padding(8).background(.black.opacity(0.9)).overlay(Rectangle().stroke(.red,lineWidth:2)) } }
