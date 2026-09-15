import SwiftUI

struct HorizonView: View {
    let pitch, roll: Double; let valid: Bool; let altitude, heading: Double?
    var body: some View { GeometryReader { g in
        let s=g.size.width
        ZStack {
            ZStack { Rectangle().fill(.blue).offset(y:-s/2); Rectangle().fill(.brown).offset(y:s/2); Rectangle().fill(.white).frame(height:3) }
                .frame(width:s*1.8,height:s*1.8).offset(y:pitch*s/45).rotationEffect(.degrees(-roll))
            ForEach([-20,-10,10,20],id:\.self){p in HStack{Rectangle().frame(width:55,height:2);Text("\(abs(p))").font(.caption.bold()).foregroundStyle(.white);Rectangle().frame(width:55,height:2)}.foregroundStyle(.white).offset(y:CGFloat(p)*s/90)}
            Path{p in p.move(to:CGPoint(x:s*.32,y:s*.5));p.addLine(to:CGPoint(x:s*.45,y:s*.5));p.addLine(to:CGPoint(x:s*.5,y:s*.54));p.addLine(to:CGPoint(x:s*.55,y:s*.5));p.addLine(to:CGPoint(x:s*.68,y:s*.5))}.stroke(.yellow,lineWidth:5)
            if let h=heading { Text(String(format:"%03.0f°",h)).font(.title2.monospacedDigit().bold()).foregroundStyle(.white).position(x:s/2,y:s*.09) }
            if let a=altitude { Text("\(Int(a)) FT").font(.title3.monospacedDigit().bold()).foregroundStyle(.white).position(x:s*.82,y:s*.5) }
            if !valid { invalid(s,"ATTITUDE INVALID") }
        }
    }}
}

struct AltimeterView: View {
    let altitude,qnh: Double; let valid: Bool
    var body: some View { GeometryReader { g in let s=g.size.width; ZStack {
        Circle().fill(.black); Circle().stroke(.white,lineWidth:3).padding(18)
        ForEach(0..<50,id:\.self){i in Capsule().fill(.white).frame(width:i%5==0 ? 3:1,height:i%5==0 ? 26:13).offset(y:-s*.42).rotationEffect(.degrees(Double(i)*7.2)) }
        ForEach(0..<10,id:\.self){i in Text("\(i)").font(.system(size:s*.065,weight:.bold,design:.rounded)).foregroundStyle(.white).offset(y:-s*.34).rotationEffect(.degrees(Double(i)*36)).rotationEffect(.degrees(-Double(i)*36)) }
        hand(s, altitude.truncatingRemainder(dividingBy:1000)*.36, s*.34, 4)
        hand(s, altitude.truncatingRemainder(dividingBy:10000)*.036, s*.26, 7)
        hand(s, altitude.truncatingRemainder(dividingBy:100000)*.0036, s*.18, 9)
        Circle().fill(.white).frame(width:14,height:14)
        Text("QNH \(Int(qnh))").font(.system(size:s*.045,weight:.bold,design:.monospaced)).foregroundStyle(.white).offset(y:s*.27)
        if !valid { invalid(s,"ALTITUDE INVALID") }
    } }}
    private func hand(_ s:CGFloat,_ deg:Double,_ length:CGFloat,_ width:CGFloat)->some View { Rectangle().fill(.white).frame(width:width,height:length).offset(y:-length/2).rotationEffect(.degrees(deg)) }
}

struct CompassView: View {
    let heading,bug: Double; let valid: Bool
    var body: some View { GeometryReader { g in let s=g.size.width; ZStack {
        Circle().fill(.black); Circle().stroke(.white,lineWidth:3).padding(18)
        ZStack {
            ForEach(0..<72,id:\.self){i in Capsule().fill(.white).frame(width:i%6==0 ? 3:1,height:i%6==0 ? 26:12).offset(y:-s*.42).rotationEffect(.degrees(Double(i)*5)) }
            ForEach(Array([(0,"N"),(90,"E"),(180,"S"),(270,"W")]),id:\.0){d,t in Text(t).font(.system(size:s*.075,weight:.bold)).foregroundStyle(.white).offset(y:-s*.32).rotationEffect(.degrees(Double(d))).rotationEffect(.degrees(-Double(d))) }
            Image(systemName:"triangle.fill").font(.title).foregroundStyle(.yellow).offset(y:-s*.34).rotationEffect(.degrees(bug))
        }.rotationEffect(.degrees(-heading))
        Image(systemName:"triangle.fill").foregroundStyle(.yellow).rotationEffect(.degrees(180)).offset(y:-s*.43)
        Path{p in p.move(to:CGPoint(x:s*.3,y:s*.5));p.addLine(to:CGPoint(x:s*.7,y:s*.5));p.move(to:CGPoint(x:s*.5,y:s*.36));p.addLine(to:CGPoint(x:s*.5,y:s*.65))}.stroke(.yellow,lineWidth:5)
        Text(String(format:"%03.0f°",heading)).font(.title.monospacedDigit().bold()).foregroundStyle(.white).offset(y:s*.27)
        if !valid { invalid(s,"HEADING INVALID") }
    } }}
}

@ViewBuilder private func invalid(_ s:CGFloat,_ text:String)->some View { ZStack { Path{p in p.move(to:CGPoint(x:s*.22,y:s*.22));p.addLine(to:CGPoint(x:s*.78,y:s*.78));p.move(to:CGPoint(x:s*.78,y:s*.22));p.addLine(to:CGPoint(x:s*.22,y:s*.78))}.stroke(.red,lineWidth:10); Text(text).font(.headline.bold()).foregroundStyle(.red).padding(8).background(.black.opacity(.8)) } }
