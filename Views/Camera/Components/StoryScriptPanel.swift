import SwiftUI
import PencilKit

// MARK: - Story Script Panel
/// Native sheet with .medium / .large detents.
/// Notes tab: TextEditor (supports Apple Pencil Scribble automatically).
/// Sketch tab: PencilKit PKCanvasView for freehand drawing.
struct StoryScriptPanel: View {
    @Binding var script: String
    @Binding var sketchData: Data?

    @Environment(\.dismiss) private var dismiss
    @State private var activeTab: StoryTab = .notes
    @State private var clearTrigger: Bool = false

    enum StoryTab: String, CaseIterable {
        case notes  = "Notes"
        case sketch = "Sketch"
        var icon: String {
            switch self {
            case .notes:  return "text.alignleft"
            case .sketch: return "scribble"
            }
        }
    }

    // Live stats (notes tab)
    private var wordCount: Int {
        script.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
              .filter { !$0.isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Tab picker ──────────────────────────────────
                Picker("Mode", selection: $activeTab) {
                    ForEach(StoryTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 10)

                Divider()

                // ── Tab content ─────────────────────────────────
                Group {
                    if activeTab == .notes {
                        notesView
                    } else {
                        sketchView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Story Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: live stats or clear action
                ToolbarItem(placement: .topBarLeading) {
                    if activeTab == .notes {
                        Text(wordCount > 0 ? "\(wordCount) word\(wordCount == 1 ? "" : "s")" : "")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .animation(.default, value: wordCount)
                    } else {
                        Button(role: .destructive) {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            clearTrigger = true
                        } label: {
                            Label("Clear", systemImage: "trash")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                        }
                        .tint(.red)
                    }
                }

                // Trailing: Done
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .tint(Color.appBlue)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(uiColor: .systemBackground))
    }

    // MARK: - Notes Tab
    private var notesView: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if script.isEmpty {
                Text("Write your story ideas, plan scenes, add a shot list or full script…\n\nTip: Use Apple Pencil Scribble to write directly here.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color(uiColor: .placeholderText))
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $script)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 16)
                .tint(Color.appBlue)
        }
    }

    // MARK: - Sketch Tab
    private var sketchView: some View {
        PencilCanvasView(data: $sketchData, clearTrigger: $clearTrigger)
    }
}

// MARK: - PencilKit Canvas (UIViewRepresentable)
struct PencilCanvasView: UIViewRepresentable {
    @Binding var data: Data?
    @Binding var clearTrigger: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(data: $data)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput          // Finger + Apple Pencil
        canvas.backgroundColor = .systemBackground
        canvas.alwaysBounceVertical = false

        // Restore existing drawing
        if let data = data,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        canvas.delegate = context.coordinator
        context.coordinator.canvas = canvas

        // Set up tool picker once and keep a strong reference in Coordinator
        let toolPicker = PKToolPicker()
        context.coordinator.toolPicker = toolPicker
        toolPicker.addObserver(canvas)
        toolPicker.setVisible(true, forFirstResponder: canvas)
        canvas.becomeFirstResponder()

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Handle clear trigger
        if clearTrigger {
            uiView.drawing = PKDrawing()
            DispatchQueue.main.async {
                self.data = nil
                self.clearTrigger = false
            }
        }
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        // Hide and detach the tool picker so it doesn't linger on screen
        if let toolPicker = coordinator.toolPicker {
            toolPicker.setVisible(false, forFirstResponder: uiView)
            toolPicker.removeObserver(uiView)
        }
        coordinator.toolPicker = nil
        uiView.resignFirstResponder()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var data: Data?
        weak var canvas: PKCanvasView?
        var toolPicker: PKToolPicker?   // Strong ref keeps it alive while sheet is open

        init(data: Binding<Data?>) { self._data = data }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let rep = canvasView.drawing.dataRepresentation()
            // Only persist if there are actual strokes
            data = canvasView.drawing.strokes.isEmpty ? nil : rep
        }
    }
}

// MARK: - Script Toggle Button
/// Compact notebook icon for Camera & Preview top bars.
struct ScriptToggleButton: View {
    let hasScript: Bool
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(isActive
                              ? Color.appBlue.opacity(0.85)
                              : Color.white.opacity(0.9))
                        .frame(width: 44, height: 44)
                    Image(systemName: "note.text")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isActive ? .white : Color.appBlue)
                }
                .shadow(color: Color.appBlue.opacity(isActive ? 0.5 : 0.15),
                        radius: 8, x: 0, y: 4)

                // Purple dot when content exists but panel is closed
                if hasScript && !isActive {
                    Circle()
                        .fill(Color.appBlue)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1.5))
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(BubbleButtonStyle())
    }
}
