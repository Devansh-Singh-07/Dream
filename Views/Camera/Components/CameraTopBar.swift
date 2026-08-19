//
//  CameraTopBar.swift
//  classMotion
//
//  Created by devansh pratap singh on 26/02/26.
//

import SwiftUI

struct CameraTopBar: View {
    let capturedFrames: [FrameData]
    let hasScript: Bool
    let isScriptVisible: Bool
    let onDismiss: () -> Void
    let onScript: () -> Void

    var body: some View {
        HStack {
            // ── Close / Finish button ──
            Button(action: onDismiss) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 44, height: 44)
                    Image(systemName: "xmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(BubbleButtonStyle())

            Spacer()

            // ── Script / Story Canvas toggle ──
            ScriptToggleButton(
                hasScript: hasScript,
                isActive: isScriptVisible,
                action: onScript
            )

            Spacer()

            // ── Frame count indicator ──
            CameraStatusPill(count: capturedFrames.count)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}
