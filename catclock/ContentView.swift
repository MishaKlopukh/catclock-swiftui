//
//  ContentView.swift
//  catclock
//
//  Created by Boris Klopukh on 7/1/24.
//

import SwiftUI

struct TailShape: Shape {
    var t: Double
    
    let _tailPoints = [
        CGPoint(x: 0,  y: 76),
        CGPoint(x: 3,  y: 82),
        CGPoint(x: 10, y: 84),
        CGPoint(x: 18, y: 82),
        CGPoint(x: 21, y: 76),
        CGPoint(x: 21, y: 70),
    ]
    let _tailOffset = CGPoint(x: 74, y: -15)
    
    func path(in rect: CGRect) -> Path {
        let theta = 0.4 * sin(t + 3 * .pi)
        let s = sin(theta), c = cos(theta)
        
        let origin = CGPoint(x: _tailOffset.x + rect.origin.x, y: _tailOffset.y + rect.origin.y)
        
        var path = Path()
        path.move(to: origin)
        
        for point in _tailPoints {
            let x = origin.x + point.x * c + point.y * s
            let y = origin.y - point.x * s + point.y * c
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
}

struct EyesShape: Shape {
    var t: Double
    
    func path(in rect: CGRect) -> Path {
        let angle = 0.7 * sin( t + 3 * .pi) + .pi / 2
        
        let origin = rect.origin
        
        var path = Path()
        path.move(to: CGPoint(x: origin.x + 12, y: origin.y - 0.5 * 23 + 11))
        
        for u in stride(from: -.pi / 2 + 0.25, to: .pi / 2, by: 0.25) {
            let px = cos(u) * cos(angle + .pi / 7)
            let py = sin(u)
            let pz = 2 + cos(u) * sin(angle + .pi / 7)
            
            let x = origin.x + ( pz == 0 ? px : px / pz ) * 23 + 12
            let y = origin.y + ( pz == 0 ? py : py / pz ) * 23 + 11
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        for u in stride(from: .pi / 2, to: -.pi / 2, by: -0.25) {
            let px = cos(u) * cos(angle - .pi / 7)
            let py = sin(u)
            let pz = 2 + cos(u) * sin(angle - .pi / 7)
            
            let x = origin.x + ( pz == 0 ? px : px / pz ) * 23 + 12
            let y = origin.y + ( pz == 0 ? py : py / pz ) * 23 + 11
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        
        return path
    }
}

struct ClockHandShape: Shape {
    var length, width, theta: Double
    
    func path(in rect: CGRect) -> Path {
        let c = cos(theta), s = sin(theta)
        let ws = width * s, wc = width * c
        
        let origin = CGPoint(
            x: rect.origin.x + rect.width / 2,
            y: rect.origin.y + rect.height / 2
        )
        
        var path = Path()
        
        path.move(to: CGPoint(
            x: origin.x + length * s,
            y: origin.y - length * c
        ))
        
        path.addLine(to: CGPoint(
            x: origin.x - (ws + wc),
            y: origin.y + (wc - ws)
        ))
        
        path.addLine(to: CGPoint(
            x: origin.x - (ws - wc),
            y: origin.y + (ws + wc)
        ))
        
        path.closeSubpath()
        
        return path
    }
}

struct CatClock: View {
    var time: DateComponents
    
    func drawClockTime(time: DateComponents) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 150, height: 300))
        return renderer.image { ctx in
            let t = (Double(time.second ?? 0 % 2) + (Double(time.nanosecond ?? 0) / 1000000000)) * .pi
            let tailShape = TailShape(t: t)
            let eyeShape = EyesShape(t: t)
            //            let secondHandShape = ClockHandShape(
            //                length: 27, width: 1,
            //                theta: 2 * .pi * Double(time.second ?? 0) / 60
            //            )
            let minuteHandShape = ClockHandShape(
                length: 27, width: 4,
                theta: 2 * .pi * Double(time.minute ?? 0) / 60
            )
            let hourHandShape = ClockHandShape(
                length: 17, width: 4,
                theta: 2 * .pi * (Double(time.hour ?? 0) + Double(time.minute ?? 0) / 60) / 12
            )
            
            let tailRect = CGRect(origin: CGPoint(x: 0, y: 211), size: CGSize(width: 150, height: 89))
            let leftEyeRect = CGRect(origin: CGPoint(x: 49, y: 30), size: CGSize(width: 54, height: 23))
            let rightEyeRect = CGRect(origin: CGPoint(x: 80, y: 30), size: CGSize(width: 54, height: 23))
            let handsRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 150, height: 300))
            
            // Draw the polygon
            ctx.cgContext.setFillColor(UIColor.black.cgColor)
            ctx.cgContext.addPath(tailShape.path(in: tailRect).cgPath)
            ctx.cgContext.addPath(eyeShape.path(in: leftEyeRect).cgPath)
            ctx.cgContext.addPath(eyeShape.path(in: rightEyeRect).cgPath)
            //            ctx.cgContext.addPath(secondHandShape.path(in: handsRect).cgPath)
            ctx.cgContext.addPath(minuteHandShape.path(in: handsRect).cgPath)
            ctx.cgContext.addPath(hourHandShape.path(in: handsRect).cgPath)
            ctx.cgContext.fillPath()
        }
    }
    
    
    var body: some View {
        ZStack {
            Image("catback")
                .resizable()
            Image(uiImage: drawClockTime(time: time))
                .resizable()
        }
        .background(Color.white)
    }
}

struct ContentView: View {
    @State private var timer: Timer?
    @State private var currentTime = DateComponents()
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            currentTime = Calendar.current.dateComponents(
                in: Calendar.current.timeZone,
                from: Date()
            )
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    var body: some View {
        CatClock(time: currentTime)
            .aspectRatio(0.5, contentMode: .fit)
            .onAppear(perform: startTimer)
            .onDisappear(perform: stopTimer)
    }
}

#Preview {
    ContentView()
}
