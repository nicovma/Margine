//
//  BrandMarkIcon.swift
//  Margine
//
//  Created by Nicolas Valentini on 13/9/2026.
//
import SwiftUI

/// The "M" mark used as the app icon, drawn from the same 24x24
/// coordinate space as the icon artwork so it stays pixel-identical
/// wherever it appears in the app.
struct BrandMarkIcon: View {
    var color: Color = .white

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 24
            mark
                .applying(CGAffineTransform(scaleX: scale, y: scale))
                .stroke(color, style: StrokeStyle(lineWidth: 2.88 * scale, lineCap: .round, lineJoin: .round))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var mark: Path {
        Path { path in
            path.move(to: CGPoint(x: 5.28, y: 18.72))
            path.addLine(to: CGPoint(x: 5.28, y: 5.76))
            path.addLine(to: CGPoint(x: 12, y: 12.48))
            path.addLine(to: CGPoint(x: 18.72, y: 5.76))
            path.addLine(to: CGPoint(x: 18.72, y: 18.72))
        }
    }
}

#Preview {
    BrandMarkIcon()
        .frame(width: 64, height: 64)
        .padding()
        .background(Color.accentColor)
}
