import SwiftUI

enum GNSSQuality: String, CaseIterable {
    case invalid = "NO FIX", poor = "POOR", weak = "WEAK", fair = "FAIR", good = "GOOD", excellent = "EXCELLENT"
    static func classify(accuracy: Double, valid: Bool, stale: Bool) -> GNSSQuality {
        guard valid, !stale, accuracy >= 0 else { return .invalid }
        if accuracy <= 1 { return .excellent }; if accuracy <= 3 { return .good }; if accuracy <= 10 { return .fair }; if accuracy <= 30 { return .weak }; return .poor
    }
    var colour: Color { switch self { case .excellent: return .green; case .good: return Color(red:0.55,green:1,blue:0.55); case .fair: return .yellow; case .weak: return .orange; case .poor,.invalid: return .red } }
}

struct GNSSPositionView: View {
    let latitude, longitude, accuracy: Double; let valid, stale: Bool
    var body: some View {
        let q=GNSSQuality.classify(accuracy:accuracy,valid:valid,stale:stale)
        VStack(spacing:2) {
            if q == .invalid { Text(stale ? "GPS STALE" : "GPS NO FIX").foregroundStyle(.red) }
            else {
                Text(String(format:"%.5f  %.5f",latitude,longitude)).foregroundStyle(q.colour)
                Text(String(format:"GPS %@  ±%.1fm",q.rawValue,accuracy)).foregroundStyle(q.colour)
            }
        }.font(.system(size:11,weight:.bold,design:.monospaced)).padding(.horizontal,6).padding(.vertical,3).background(.black.opacity(0.82))
    }
}

struct HorizonView: View {
    let pitch, roll: Double; let valid: Bool; let altitude, heading: Double?
    let gpsLatitude, gpsLongitude, gpsAccuracy: Double; let gpsValid, gpsStale: Bool
    private let bankMarks = [10,20,30,45,60]
    var body: some View { GeometryReader { g in let s=g.size.width; ZStack {
        ZStack { Rectangle().fill(.blue).offset(y:-s/2); Rectangle().fill(.brown).offset(y:s/2); Rectangle().fill(.white).frame(height:4)
            ForEach([-20,-15,-10,-5,5,10,15,20],id:\.self){ p in let major=abs(p)%10==0; HStack(spacing:major ? s*.075:s*.05){Rectangle().frame(width:major ? s*.10:s*.055,height:major ? 3:2);Rectangle().frame(width:major ? s*.10:s*.055,height:major ? 3:2)}.foregroundStyle(.white).offset(y:CGFloat(p)*s/66.18) }
        }.frame(width:s*1.8,height:s*1.8).offset(y:pitch*s/70.59).rotationEffect(.degrees(-roll))
        ForEach(bankMarks,id:\.self){d in let major=d==30 || d==60; Capsule().fill(.white).frame(width:major ? 4:3,height:major ? s*.052:s*.04).offset(y:-s*.395).rotationEffect(.degrees(Double(d)));Capsule().fill(.white).frame(width:major ? 4:3,height:major ? s*.052:s*.04).offset(y:-s*.395).rotationEffect(.degrees(Double(-d)))}
        Capsule().fill(.white).frame(width:4,height:s*.062).offset(y:-s*.39)
        Path{p in p.move(to:CGPoint(x:s*.5,y:s*.148));p.addLine(to:CGPoint(x:s*.481,y:s*.188));p.addLine(to:CGPoint(x:s*.519,y:s*.188));p.closeSubpath()}.stroke(.black,lineWidth:7).rotationEffect(.degrees(roll))
        Path{p in p.move(to:CGPoint(x:s*.5,y:s*.148));p.addLine(to:CGPoint(x:s*.481,y:s*.188));p.addLine(to:CGPoint(x:s*.519,y:s*.188));p.closeSubpath()}.stroke(.white,lineWidth:3).rotationEffect(.degrees(roll))
        Path{p in p.move(to:CGPoint(x:s*.308,y:s*.5));p.addLine(to:CGPoint(x:s*.45,y:s*.5));p.move(to:CGPoint(x:s*.692,y:s*.5));p.addLine(to:CGPoint(x:s*.55,y:s*.5));p.move(to:CGPoint(x:s*.45,y:s*.5));p.addLine(to:CGPoint(x:s*.479,y:s*.527));p.move(to:CGPoint(x:s*.55,y:s*.5));p.addLine(to:CGPoint(x:s*.521,y:s*.527));p.move(to:CGPoint(x:s*.479,y:s*.527));p.addLine(to:CGPoint(x:s*.521,y:s*.527))}.stroke(.black,lineWidth:9)
        Path{p in p.move(to:CGPoint(x:s*.308,y:s*.5));p.addLine(to:CGPoint(x:s*.45,y:s*.5));p.move(to:CGPoint(x:s*.692,y:s*.5));p.addLine(to:CGPoint(x:s*.55,y:s*.5));p.move(to:CGPoint(x:s*.45,y:s*.5));p.addLine(to:CGPoint(x:s*.479,y:s*.527));p.move(to:CGPoint(x:s*.55,y:s*.5));p.addLine(to:CGPoint(x:s*.521,y:s*.527));p.move(to:CGPoint(x:s*.479,y:s*.527));p.addLine(to:CGPoint(x:s*.521,y:s*.527))}.stroke(.yellow,lineWidth:5)
        if let h=heading { Text(String(format:"%03.0f",h)).font(.title2.monospacedDigit().bold()).foregroundStyle(.white).position(x:s/2,y:s*.09) }
        if let a=altitude { Text("\(Int(a)) FT").font(.title3.monospacedDigit().bold()).foregroundStyle(.white).position(x:s*.82,y:s*.5) }
        GNSSPositionView(latitude:gpsLatitude,longitude:gpsLongitude,accuracy:gpsAccuracy,valid:gpsValid,stale:gpsStale).position(x:s/2,y:s*.79)
        if !valid { invalid(s,"ATT FAIL") }
    } }}
}

struct AltimeterView: View {
    let altitude,qnh: Double; let valid: Bool
    var body: some View { GeometryReader { g in let s=g.size.width;let a=max(0,altitude); ZStack { Circle().fill(.black);Circle().stroke(.gray,lineWidth:s*.03).padding(s*.015);Circle().stroke(.white,lineWidth:3).padding(s*.045);ForEach(0..<50,id:\.self){i in Capsule().fill(.white).frame(width:i%5==0 ? 3:1,height:i%5==0 ? s*.058:s*.026).offset(y:-s*.405).rotationEffect(.degrees(Double(i)*7.2))};ForEach(0..<10,id:\.self){i in Text("\(i)").font(.system(size:s*.065,weight:.bold,design:.rounded)).foregroundStyle(.white).offset(y:-s*.33).rotationEffect(.degrees(Double(i)*36)).rotationEffect(.degrees(-Double(i)*36))};Text("ALT").font(.system(size:s*.045,weight:.bold,design:.monospaced)).foregroundStyle(.white).offset(y:-s*.18);Text("FEET").font(.system(size:s*.027,weight:.bold,design:.monospaced)).foregroundStyle(.gray).offset(y:-s*.125);kollsman(s);if valid { if a>10000{altitudeHatching(s,altitude:a)};hand(s,a.truncatingRemainder(dividingBy:1000)*.36,s*.30,3);hand(s,a.truncatingRemainder(dividingBy:10000)*.036,s*.22,5);hand(s,a.truncatingRemainder(dividingBy:100000)*.0036,s*.145,7);Circle().fill(.white).frame(width:s*.03,height:s*.03);Text("\(Int(a))").font(.system(size:s*.052,weight:.bold,design:.monospaced)).foregroundStyle(.green).padding(.horizontal,s*.025).padding(.vertical,s*.012).background(.black).overlay(Rectangle().stroke(.white,lineWidth:1)).offset(y:s*.16)}else{invalid(s,"ALT FAIL")} } }}
    private func hand(_ s:CGFloat,_ deg:Double,_ length:CGFloat,_ width:CGFloat)->some View { Rectangle().fill(.white).frame(width:width,height:length).offset(y:-length/2).rotationEffect(.degrees(deg)) }
    @ViewBuilder private func kollsman(_ s:CGFloat)->some View { let degreesPerHpa=2.0,halfWindow=8.0;let pressures=Array(950...1050).filter{abs((Double($0)-qnh)*degreesPerHpa)<=halfWindow};ZStack{AnnularSector(startDegrees:-halfWindow,endDegrees:halfWindow,innerFraction:0.61).fill(.black).frame(width:s*.85,height:s*.85);ForEach(pressures,id:\.self){p in let delta=(Double(p)-qnh)*degreesPerHpa;let major=p%5==0;Capsule().fill(.white).frame(width:major ? 2:1,height:major ? s*.055:s*.042).offset(y:-s*.383).rotationEffect(.degrees(90+delta));if major{Text("\(p)").font(.system(size:s*.025,weight:.bold,design:.monospaced)).foregroundStyle(.white).offset(x:s*.315).rotationEffect(.degrees(delta)).rotationEffect(.degrees(-delta))}};let stdDelta=(1013.25-qnh)*degreesPerHpa;if abs(stdDelta)<=halfWindow{Capsule().fill(.white).frame(width:5,height:s*.065).offset(y:-s*.375).rotationEffect(.degrees(90+stdDelta))};Capsule().fill(.white).frame(width:3,height:s*.075).offset(y:-s*.383).rotationEffect(.degrees(90))} }
    @ViewBuilder private func altitudeHatching(_ s:CGFloat,altitude:Double)->some View {let fraction=min(1,max(0,(altitude-10000)/1000)),sweep=60.0*fraction;ZStack{ForEach(-8...8,id:\.self){i in Rectangle().fill(.white).frame(width:2,height:s*.20).rotationEffect(.degrees(45)).offset(x:CGFloat(i)*s*.022)}}.frame(width:s*.31,height:s*.31).clipShape(AnnularSector(startDegrees:240,endDegrees:240+sweep,innerFraction:0.70)).offset(x:-s*.285)}
}

private struct AnnularSector: Shape { let startDegrees:Double;let endDegrees:Double;let innerFraction:CGFloat;func path(in rect:CGRect)->Path{let c=CGPoint(x:rect.midX,y:rect.midY),r=min(rect.width,rect.height)/2,ir=r*innerFraction;var p=Path();p.addArc(center:c,radius:r,startAngle:.degrees(startDegrees),endAngle:.degrees(endDegrees),clockwise:false);p.addArc(center:c,radius:ir,startAngle:.degrees(endDegrees),endAngle:.degrees(startDegrees),clockwise:true);p.closeSubpath();return p} }

struct CompassView: View {
    let heading,bug: Double; let valid: Bool
    let gpsLatitude, gpsLongitude, gpsAccuracy: Double; let gpsValid, gpsStale: Bool
    private func relative(_ selected:Double,_ heading:Double)->Double{var d=(selected-heading).truncatingRemainder(dividingBy:360);if d<0{d+=360};return d}
    var body: some View { GeometryReader { g in let s=g.size.width;let hdg=((heading.truncatingRemainder(dividingBy:360))+360).truncatingRemainder(dividingBy:360);ZStack{Circle().fill(.black);Circle().stroke(.gray,lineWidth:s*.03).padding(s*.015);Circle().stroke(.white,lineWidth:3).padding(s*.045);ZStack{ForEach(0..<72,id:\.self){i in Capsule().fill(.white).frame(width:i%6==0 ? 3:1,height:i%6==0 ? s*.058:(i%2==0 ? s*.038:s*.022)).offset(y:-s*.405).rotationEffect(.degrees(Double(i)*5))};ForEach(Array([(0,"N"),(90,"E"),(180,"S"),(270,"W")]),id:\.0){d,t in Text(t).font(.system(size:s*.065,weight:.bold,design:.rounded)).foregroundStyle(.white).offset(y:-s*.32).rotationEffect(.degrees(Double(d))).rotationEffect(.degrees(-Double(d)))}}.rotationEffect(.degrees(-hdg));Path{p in p.move(to:CGPoint(x:s*.5,y:s*.038));p.addLine(to:CGPoint(x:s*.472,y:s*.10));p.addLine(to:CGPoint(x:s*.528,y:s*.10));p.closeSubpath()}.stroke(.yellow,lineWidth:3);Path{p in p.move(to:CGPoint(x:s*.5,y:s*.075));p.addLine(to:CGPoint(x:s*.475,y:s*.125));p.addLine(to:CGPoint(x:s*.525,y:s*.125));p.closeSubpath()}.stroke(.yellow,lineWidth:4).rotationEffect(.degrees(relative(bug,hdg)));Path{p in p.move(to:CGPoint(x:s*.34,y:s*.51));p.addLine(to:CGPoint(x:s*.66,y:s*.51));p.move(to:CGPoint(x:s*.5,y:s*.37));p.addLine(to:CGPoint(x:s*.5,y:s*.64));p.move(to:CGPoint(x:s*.43,y:s*.64));p.addLine(to:CGPoint(x:s*.5,y:s*.585));p.addLine(to:CGPoint(x:s*.57,y:s*.64))}.stroke(.yellow,lineWidth:5);Text(String(format:"%03.0f",hdg)).font(.system(size:s*.075,weight:.bold,design:.monospaced)).foregroundStyle(.green).padding(.horizontal,s*.025).padding(.vertical,s*.012).background(.black).overlay(Rectangle().stroke(.white,lineWidth:1)).offset(y:s*.18);GNSSPositionView(latitude:gpsLatitude,longitude:gpsLongitude,accuracy:gpsAccuracy,valid:gpsValid,stale:gpsStale).position(x:s/2,y:s*.78);if !valid{invalid(s,"HDG FAIL")}} }}
}

@ViewBuilder private func invalid(_ s:CGFloat,_ text:String)->some View { ZStack { Path{p in p.move(to:CGPoint(x:s*.22,y:s*.22));p.addLine(to:CGPoint(x:s*.78,y:s*.78));p.move(to:CGPoint(x:s*.78,y:s*.22));p.addLine(to:CGPoint(x:s*.22,y:s*.78))}.stroke(.red,lineWidth:10);Text(text).font(.headline.bold()).foregroundStyle(.red).padding(8).background(.black.opacity(.9)).overlay(Rectangle().stroke(.red,lineWidth:2)) } }
