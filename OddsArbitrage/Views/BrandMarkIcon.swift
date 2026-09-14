//
//  BrandMarkIcon.swift
//  OddsArbitrage
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

/// The ball-and-flow mark used as the app icon, drawn from the same
/// 24x24 coordinate space as the icon artwork so it stays pixel-identical
/// wherever it appears in the app.
struct BrandMarkIcon: View {
    var color: Color = .white

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 24
            ZStack {
                Circle()
                    .strokeBorder(color, lineWidth: 1.6 * scale)
                pentagon
                    .applying(CGAffineTransform(scaleX: scale, y: scale))
                    .fill(color)
                spokes
                    .applying(CGAffineTransform(scaleX: scale, y: scale))
                    .stroke(color, lineWidth: 1.1 * scale)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var pentagon: Path {
        Path { path in
            path.move(to: CGPoint(x: 12, y: 6.2))
            path.addLine(to: CGPoint(x: 14.6, y: 8.1))
            path.addLine(to: CGPoint(x: 13.6, y: 11.1))
            path.addLine(to: CGPoint(x: 10.4, y: 11.1))
            path.addLine(to: CGPoint(x: 9.4, y: 8.1))
            path.closeSubpath()
        }
    }

    private var spokes: Path {
        Path { path in
            func line(_ from: CGPoint, _ to: CGPoint) {
                path.move(to: from)
                path.addLine(to: to)
            }
            line(CGPoint(x: 12, y: 6.2), CGPoint(x: 9.4, y: 8.1))
            line(CGPoint(x: 12, y: 6.2), CGPoint(x: 14.6, y: 8.1))
            line(CGPoint(x: 10.4, y: 11.1), CGPoint(x: 7.3, y: 12))
            line(CGPoint(x: 13.6, y: 11.1), CGPoint(x: 16.7, y: 12))
            line(CGPoint(x: 10.4, y: 11.1), CGPoint(x: 11.3, y: 14.6))
            line(CGPoint(x: 13.6, y: 11.1), CGPoint(x: 12.7, y: 14.6))
        }
    }
}

#Preview {
    BrandMarkIcon()
        .frame(width: 64, height: 64)
        .padding()
        .background(Color.accentColor)
}
