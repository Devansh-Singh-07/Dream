//
//  CameraActionButton.swift
//  classMotion
//
//  Created by devansh pratap singh on 26/02/26.
//

import SwiftUI

struct CameraActionButtons: View {
    let capturedCount: Int
    let captureScale: CGFloat
    let onCapture: () -> Void
    let onUndo: () -> Void
    let onDone: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            GlassIconButton(icon: "arrow.uturn.backward", label: "Undo", tint: .appBlue, action: onUndo)
                .disabled(capturedCount == 0)
                .opacity(capturedCount == 0 ? 0.35 : 1)

            Spacer()

            CameraCaptureButton(isComplete: false, scale: captureScale, action: onCapture)

            Spacer()

            GlassIconButton(icon: "checkmark", label: "Done", tint: .appGreen, action: onDone)
                .disabled(capturedCount == 0)
                .opacity(capturedCount == 0 ? 0.35 : 1)
        }
        .padding(.horizontal, 30)
    }
}

struct GlassIconButton: View {
    let icon: String
    let label: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(tint)
                }
                .shadow(color: tint.opacity(0.2), radius: 8, x: 0, y: 4)
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .buttonStyle(BubbleButtonStyle())
    }
}
