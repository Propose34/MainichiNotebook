import SwiftUI
import PencilKit

struct WritingPracticeDetailScreen: View {
    let character: WritingPracticeCharacter
    var isEmbedded: Bool = false
    
    @EnvironmentObject var progressService: WritingPracticeProgressService
    @State private var drawing = PKDrawing()
    @State private var showTraceGuide = true
    @State private var showingClearConfirmation = false
    @State private var showingEmptySaveConfirmation = false
    @State private var showingSaveSuccess = false
    
    // Custom Canvas Tool State
    @State private var selectedTool: WritingPracticeTool = .pen
    @State private var strokeWidth: CGFloat = 5.5
    @State private var selectedColor: Color = AppTheme.darkNavy
    @StateObject private var canvasController = WritingPracticeCanvasController()
    
    // Tools options data
    private let colors = [
        (color: AppTheme.darkNavy, name: "Black"),
        (color: AppTheme.sakuraPink, name: "Pink"),
        (color: Color(hex: "3D5A80"), name: "Blue"),
        (color: AppTheme.textMuted, name: "Gray")
    ]
    
    private let widths = [
        (width: CGFloat(2.0), label: "Thin"),
        (width: CGFloat(6.0), label: "Normal"),
        (width: CGFloat(14.0), label: "Thick")
    ]
    
    var body: some View {
        ZStack {
            AppTheme.paperBackground
                .ignoresSafeArea()
            
            if isEmbedded {
                // Non-scrolling compact vertical stack for iPad split pane to prevent cutoffs
                VStack(spacing: 12) {
                    topInfoRow
                    toolStrip
                    canvasGrid
                    saveButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxHeight: .infinity, alignment: .top)
            } else {
                // Scrollable layout for iPhone vertical screens
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            Spacer()
                            Text(character.mode.rawValue)
                                .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.sakuraPink)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppTheme.sakuraPinkLight)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        topInfoRow
                            .padding(.horizontal, 20)
                        
                        toolStrip
                            .padding(.horizontal, 20)
                        
                        canvasGrid
                            .padding(.horizontal, 20)
                        
                        saveButton
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }
            }
            
            // Visual feedback on saved practice
            if showingSaveSuccess {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.sageGreen)
                        Text("Practice saved successfully!")
                            .font(AppTheme.fontRounded(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppTheme.paperCard)
                    .cornerRadius(12)
                    .shadow(color: AppTheme.shadowColor, radius: 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 40)
                }
                .zIndex(10)
            }
        }
        .onAppear {
            loadDrawing()
        }
        .onChange(of: character) { _ in
            loadDrawing()
        }
        .alert("Clear Practice Sheet", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                clearCanvas()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear your drawing?")
        }
        .alert("Save Empty Canvas?", isPresented: $showingEmptySaveConfirmation) {
            Button("Save Anyway", role: .none) {
                confirmSavePractice()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("No strokes drawn yet. Tap Save anyway to mark as practiced?")
        }
    }
    
    // MARK: - Subviews
    
    private var topInfoRow: some View {
        HStack(spacing: 16) {
            // Left: StrokeOrderVisualGuideView (ตัวโชว์) showing stroke numbers and directions
            StrokeOrderVisualGuideView(character: character.character, size: 120)
                .shadow(color: AppTheme.shadowColor, radius: 4)
            
            // Right: Compact Info Panel
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(character.reading.uppercased())
                        .font(AppTheme.fontRounded(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.sakuraPink)
                        .tracking(1)
                    
                    Spacer()
                    
                    Button(action: speakCharacter) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.sakuraPink)
                            .padding(6)
                            .background(AppTheme.sakuraPinkLight)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if let meaning = character.meaning {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("MEANING")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        Text(meaning)
                            .font(AppTheme.fontRounded(size: 13, weight: .bold))
                            .foregroundColor(AppTheme.textDark)
                            .lineLimit(2)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("GROUP / LEVEL")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        Text(character.group)
                            .font(AppTheme.fontRounded(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textDark)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("PRACTICED")
                            .font(AppTheme.fontRounded(size: 8, weight: .bold))
                            .foregroundColor(AppTheme.textMuted)
                        Text("\(progressService.practiceCount(for: character.id)) times")
                            .font(AppTheme.fontRounded(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.textDark)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: 120, alignment: .leading)
            .background(AppTheme.paperCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.borderLight, lineWidth: 1.5)
            )
            .shadow(color: AppTheme.shadowColor, radius: 4)
        }
        .frame(maxWidth: 420)
    }
    
    private var toolStrip: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Tool selectors
                HStack(spacing: 6) {
                    ForEach(WritingPracticeTool.allCases) { tool in
                        Button(action: { selectedTool = tool }) {
                            Image(systemName: tool.iconName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(selectedTool == tool ? .white : AppTheme.textMuted)
                                .frame(width: 28, height: 28)
                                .background(selectedTool == tool ? AppTheme.sakuraPink : AppTheme.paperBeige)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Divider()
                    .frame(height: 20)
                
                // Colors
                HStack(spacing: 6) {
                    ForEach(colors, id: \.color) { item in
                        Button(action: {
                            selectedColor = item.color
                            if selectedTool == .eraser {
                                selectedTool = .pen
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == item.color && selectedTool != .eraser ? 1.5 : 0)
                                    )
                                
                                if selectedColor == item.color && selectedTool != .eraser {
                                    Circle()
                                        .stroke(AppTheme.sakuraPink, lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedTool == .eraser)
                        .opacity(selectedTool == .eraser ? 0.3 : 1.0)
                    }
                }
                
                Spacer()
                
                // Widths
                HStack(spacing: 4) {
                    ForEach(widths, id: \.width) { item in
                        Button(action: { strokeWidth = item.width }) {
                            Text(item.label)
                                .font(AppTheme.fontRounded(size: 8, weight: .bold))
                                .foregroundColor(strokeWidth == item.width && selectedTool != .eraser ? .white : AppTheme.textMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(strokeWidth == item.width && selectedTool != .eraser ? AppTheme.darkNavy : AppTheme.paperBeige)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(selectedTool == .eraser)
                        .opacity(selectedTool == .eraser ? 0.3 : 1.0)
                    }
                }
            }
            
            Divider()
            
            // Row 2: Action commands (Undo, Redo, Clear)
            HStack {
                Toggle(isOn: $showTraceGuide) {
                    Text("Trace Guide")
                        .font(AppTheme.fontRounded(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textDark)
                }
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.sakuraPink))
                .fixedSize()
                
                Spacer()
                
                // Undo
                Button(action: { canvasController.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(canvasController.canUndo ? AppTheme.textDark : AppTheme.textMuted.opacity(0.3))
                        .frame(width: 26, height: 26)
                        .background(AppTheme.paperBeige)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canvasController.canUndo)
                
                // Redo
                Button(action: { canvasController.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(canvasController.canRedo ? AppTheme.textDark : AppTheme.textMuted.opacity(0.3))
                        .frame(width: 26, height: 26)
                        .background(AppTheme.paperBeige)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!canvasController.canRedo)
                
                // Clear
                Button(action: { showingClearConfirmation = true }) {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .foregroundColor(Color.red.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(AppTheme.paperCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.borderLight, lineWidth: 1.5)
        )
        .frame(maxWidth: 420)
    }
    
    private var canvasGrid: some View {
        ZStack {
            // Paper grid background
            PracticeGridPaperView()
            
            // Trace Guide Faint Letter directly centered behind the canvas
            if showTraceGuide {
                Text(character.character)
                    .font(AppTheme.fontSerif(size: character.mode == .kanji ? 180 : 210, weight: .thin))
                    .foregroundColor(AppTheme.textDark.opacity(0.06))
                    .allowsHitTesting(false)
            }
            
            // Transparent PencilKit writing canvas (กล่องเปล่า) where user practices
            WritingPracticeCanvasView(
                drawing: $drawing,
                toolType: selectedTool,
                strokeWidth: strokeWidth,
                strokeColor: selectedColor,
                controller: canvasController
            )
            .cornerRadius(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 420)
        .shadow(color: AppTheme.shadowColor, radius: 6)
    }
    
    private var saveButton: some View {
        Button(action: savePractice) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down.fill")
                Text("Save Practice Progress")
            }
            .font(AppTheme.fontRounded(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.darkNavy)
            .cornerRadius(12)
            .shadow(color: AppTheme.darkNavy.opacity(0.2), radius: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: 420)
    }
    
    // MARK: - Actions
    
    private func loadDrawing() {
        self.drawing = progressService.loadDrawing(forCharacterId: character.id)
    }
    
    private func clearCanvas() {
        canvasController.clear()
        self.drawing = PKDrawing()
    }
    
    private func savePractice() {
        if drawing.strokes.isEmpty {
            showingEmptySaveConfirmation = true
        } else {
            confirmSavePractice()
        }
    }
    
    private func confirmSavePractice() {
        // Save current strokes in documents directory
        progressService.saveDrawing(drawing, forCharacterId: character.id)
        
        // Save database progress counters
        progressService.markPracticed(characterId: character.id, mode: character.mode)
        
        // Show success animation
        withAnimation(.easeOut(duration: 0.2)) {
            showingSaveSuccess = true
        }
        
        // Auto-dismiss save feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeIn(duration: 0.2)) {
                showingSaveSuccess = false
            }
        }
    }
    
    private func speakCharacter() {
        let _ = JapanesePronunciationService.shared.speakText(character.character)
    }
}
