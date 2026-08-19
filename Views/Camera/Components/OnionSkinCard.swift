//
//  OnionSkinCard.swift
//  classMotion
//
//  Created by devansh pratap singh on 26/02/26.
//
import SwiftUI

struct OnionSkinCard: View {
    @Binding var opacity: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle().fill(Color.appBlue.opacity(0.2)).frame(width: 28, height: 28)
                        Image(systemName: "square.stack.3d.down.forward.fill").font(.caption).foregroundStyle(Color.appBlue)
                    }
                    Text("Ghost Frame").font(.system(.callout, design: .rounded, weight: .semibold)).foregroundStyle(.white)
                }
                Spacer()
                Text("\(Int(opacity * 100))%")
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                    .monospacedDigit()
            }
            HStack(spacing: 16) {
                Image(systemName: "eye.slash.fill").font(.caption).foregroundStyle(.white.opacity(0.5)).frame(width: 20)
                Slider(value: $opacity, in: 0...1)
                    .tint(Color.appBlue)
                Image(systemName: "eye.fill").font(.caption).foregroundStyle(.white.opacity(0.5)).frame(width: 20)
            }
        }
        .padding(20)
        .glassEffect(cornerRadius: .cornerRadius)
    }
}
