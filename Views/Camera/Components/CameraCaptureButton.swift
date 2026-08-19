//
//  CameraCaptureButton.swift
//  classMotion
//
//  Created by devansh pratap singh on 26/02/26.
//

import SwiftUI

struct CameraCaptureButton: View {
    let isComplete: Bool
    let scale: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.appPink.opacity(0.25), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 55
                        )
                    )
                    .frame(width: 110, height: 110)
                    .blur(radius: 8)

                // Rainbow ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.appBlue, .appPurple, .appPink, .appOrange, .appYellow, .appGreen, .appBlue],
                            center: .center
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 88, height: 88)

                // Inner candy button
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.appPink, .appRed],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 72, height: 72)

                // Camera icon
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                if isComplete {
                    Circle()
                        .stroke(Color.appGreen, lineWidth: 4)
                        .frame(width: 88, height: 88)
                        .scaleEffect(scale)
                        .opacity(2 - scale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: scale)
                }
            }
            .scaleEffect(scale)
            .animation(.spring(response: 0.25, dampingFraction: 0.55), value: scale)
            .shadow(color: .appPink.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 12)
    }
}
