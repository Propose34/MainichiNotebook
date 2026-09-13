import SwiftUI
import PhotosUI

struct PaperTemplatePickerView: View {
    @EnvironmentObject private var templateService: PaperTemplateService
    @Environment(\.dismiss) var dismiss
    
    // Callbacks
    let onApplyToCurrent: (PaperTemplate) -> Void
    let onAddNewPage: (PaperTemplate) -> Void
    
    @State private var selectedTab: String = "All"
    @State private var showingFileImporter = false
    @State private var importNameText = ""
    @State private var showingImportNameAlert = false
    @State private var pendingImportURL: URL? = nil
    
    // Rename state
    @State private var templateToRename: PaperTemplate? = nil
    @State private var renameText = ""
    @State private var showingRenameAlert = false
    
    // Delete state
    @State private var templateToDelete: PaperTemplate? = nil
    @State private var showingDeleteAlert = false
    
    let tabs = ["All", "Favorites", "Presets", "Study Sheets", "Custom"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tabs, id: \.self) { tab in
                            Button(action: { selectedTab = tab }) {
                                Text(tab)
                                    .font(AppTheme.fontRounded(size: 13, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == tab ? AppTheme.darkNavy : AppTheme.paperCard)
                                    .foregroundColor(selectedTab == tab ? AppTheme.paperBackground : AppTheme.textDark)
                                    .cornerRadius(18)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(AppTheme.borderLight, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(AppTheme.paperBeige.opacity(0.15))
                
                // Grid of templates
                ScrollView {
                    let filtered = getFilteredTemplates()
                    
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(AppTheme.textMuted.opacity(0.4))
                                .padding(.top, 60)
                            Text("No templates found in this tab.\nไม่มีแผ่นกระดาษตัวอย่างในแท็บนี้")
                                .font(AppTheme.fontRounded(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 140, maximum: .infinity), spacing: 20)
                            ],
                            spacing: 24
                        ) {
                            ForEach(filtered) { template in
                                templateCell(for: template)
                            }
                        }
                        .padding(20)
                    }
                }
                .background(AppTheme.paperBackground)
            }
            .navigationTitle("Template Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFileImporter = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Import Custom")
                        }
                        .font(AppTheme.fontRounded(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.sakuraPink)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(AppTheme.fontRounded(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.image, .pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    // Trigger custom name input
                    pendingImportURL = url
                    importNameText = url.deletingPathExtension().lastPathComponent
                    showingImportNameAlert = true
                case .failure(let error):
                    print("Import selection failed: \(error)")
                }
            }
            .alert("Import Template / ตั้งชื่อเทมเพลต", isPresented: $showingImportNameAlert) {
                TextField("Enter template name", text: $importNameText)
                Button("Import") {
                    confirmImport()
                }
                Button("Cancel", role: .cancel) {
                    pendingImportURL = nil
                }
            } message: {
                Text("Give your imported image/PDF paper template a display name.")
            }
            .alert("Rename Template / เปลี่ยนชื่อ", isPresented: $showingRenameAlert) {
                TextField("New Name", text: $renameText)
                Button("Rename") {
                    if let t = templateToRename {
                        templateService.renameTemplate(id: t.id, newName: renameText)
                        templateToRename = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    templateToRename = nil
                }
            }
            .alert("Delete Template", isPresented: $showingDeleteAlert, presenting: templateToDelete) { template in
                Button("Delete", role: .destructive) {
                    templateService.deleteTemplate(id: template.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: { template in
                Text("Delete custom template \"\(template.name)\"? Notebook pages currently using this background will fall back safely to a blank grid paper.")
            }
        }
    }
    
    // MARK: - Filter Logic
    
    private func getFilteredTemplates() -> [PaperTemplate] {
        let all = templateService.templates
        switch selectedTab {
        case "Favorites":
            return all.filter { $0.isFavorite }
        case "Presets":
            // blank, ruled, grid, dotGrid, genkou, kana, kanji
            let presets = ["blank", "ruled", "grid", "dotGrid", "genkouYoushi", "kana", "kanji"]
            return all.filter { $0.kind == .builtIn && presets.contains($0.builtInPresetId ?? "") }
        case "Study Sheets":
            let sheets = ["vocabTable", "simpleVocab", "kanjiStudy", "grammarPattern", "sentencePractice", "lessonSummary", "cornellNotes", "dailyPlanner"]
            return all.filter { $0.kind == .builtIn && sheets.contains($0.builtInPresetId ?? "") }
        case "Custom":
            return all.filter { $0.kind != .builtIn }
        default:
            return all
        }
    }
    
    // MARK: - Template Cell View
    
    @ViewBuilder
    private func templateCell(for template: PaperTemplate) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Interactive Card
                VStack(spacing: 0) {
                    TemplateThumbnailView(template: template)
                        .padding(.vertical, 8)
                }
                .frame(width: 120, height: 140)
                .background(AppTheme.paperCard)
                .cornerRadius(12)
                .shadow(color: AppTheme.shadowColor, radius: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.borderLight, lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    print("[PaperTemplatePickerView] Card tapped for template: \(template.name)")
                    onApplyToCurrent(template)
                    dismiss()
                }
                .contextMenu {
                    Button(action: { onApplyToCurrent(template); dismiss() }) {
                        Label("Apply to Current Page", systemImage: "paintbrush")
                    }
                    Button(action: { onAddNewPage(template); dismiss() }) {
                        Label("Add New Page with this", systemImage: "doc.badge.plus")
                    }
                    
                    if template.kind != .builtIn {
                        Button {
                            renameText = template.name
                            templateToRename = template
                            showingRenameAlert = true
                        } label: {
                            Label("Rename Template", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            templateToDelete = template
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Template", systemImage: "trash")
                        }
                    }
                }
                
                // Favorite Star
                Button {
                    templateService.toggleFavorite(id: template.id)
                } label: {
                    Image(systemName: template.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(template.isFavorite ? .orange : AppTheme.textMuted.opacity(0.4))
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Text Details
            VStack(spacing: 2) {
                Text(template.name)
                    .font(AppTheme.fontRounded(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.textDark)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                if let sub = template.subtitle {
                    Text(sub)
                        .font(AppTheme.fontRounded(size: 9, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .lineLimit(1)
                }
            }
            .frame(width: 130)
            
            // Fast Action Bar
            HStack(spacing: 8) {
                Text("Apply")
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.sakuraPink.opacity(0.15))
                    .foregroundColor(AppTheme.sakuraPink)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("[PaperTemplatePickerView] Fast Action Apply tapped for template: \(template.name)")
                        onApplyToCurrent(template)
                        dismiss()
                    }
                
                Text("+ New")
                    .font(AppTheme.fontRounded(size: 10, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppTheme.sageGreen.opacity(0.15))
                    .foregroundColor(AppTheme.sageGreen)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("[PaperTemplatePickerView] Fast Action + New tapped for template: \(template.name)")
                        onAddNewPage(template)
                        dismiss()
                    }
            }
        }
    }
    
    // MARK: - Actions helpers
    
    private func confirmImport() {
        guard let url = pendingImportURL else { return }
        Task {
            let _ = await templateService.importTemplate(from: url, name: importNameText)
            pendingImportURL = nil
        }
    }
}

// MARK: - Thumbnail Helper Component
struct TemplateThumbnailView: View {
    let template: PaperTemplate
    @EnvironmentObject private var service: PaperTemplateService
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 72, height: 96)
                .shadow(color: Color.black.opacity(0.08), radius: 2)
            
            if template.kind == .builtIn, let presetId = template.builtInPresetId {
                BuiltInPaperTemplateBackgroundView(presetId: presetId)
                    .frame(width: 720, height: 960)
                    .scaleEffect(72.0 / 720.0)
                    .frame(width: 72, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if let thumb = template.thumbnailFileName {
                let url = service.getTemplateThumbnailURL(fileName: thumb)
                if let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    fallbackPlaceholder
                }
            } else {
                fallbackPlaceholder
            }
        }
    }
    
    private var fallbackPlaceholder: some View {
        ZStack {
            Color(hex: "F3EFE6")
            Image(systemName: template.kind == .importedPDF ? "doc.richtext" : "doc.image")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textMuted.opacity(0.5))
        }
        .frame(width: 72, height: 96)
        .cornerRadius(6)
    }
}
