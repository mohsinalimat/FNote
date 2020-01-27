//
//  NoteCardForm.swift
//  FNote
//
//  Created by Dara Beng on 1/20/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import SwiftUI


struct NoteCardForm: View {
    
    @ObservedObject var viewModel: NoteCardFormModel
    
    @State private var sheet: Sheet?
    @State private var modalTextViewModel = ModalTextViewModel()
    @State private var relationshipViewModel = NoteCardCollectionViewModel()
    
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: Native & Translation
                Section(header: Text("NATIVE & TRANSLATION").padding(.top, 24)) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(viewModel.nativePlaceholder, text: $viewModel.native)
                            .font(.headline)
                        Text("native")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField(viewModel.translationPlaceholder, text: $viewModel.translation)
                            .font(Font.headline.weight(.regular))
                        Text("translation")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: Collection
                Section(header: Text("COLLECTION")) {
                    NavigationLink(
                        destination: NoteCardFormCollectionSelectionView(formModel: viewModel),
                        isActive: $viewModel.isSelectingCollection
                    ) {
                        HStack {
                            Text(viewModel.selectedCollection?.name ?? "None")
                                .foregroundColor(viewModel.selectedCollection == nil ? .secondary : .primary)
                            Spacer()
                            Text(viewModel.selectedCollectionNoteCardCount)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("FORMALITY")) {
                    // MARK: Formality
                    SegmentControlWrapper(
                        selectedIndex: $viewModel.formality,
                        segments: viewModel.formalities,
                        selectedColor: viewModel.selectedFormality.uiColor
                    )
                }
                
                Section {
                    // MARK: Favorite
                    Toggle(isOn: $viewModel.isFavorite) {
                        Image.noteCardFavorite(viewModel.isFavorite)
                            .frame(width: 20, height: 20, alignment: .center)
                        Text("Favorite")
                    }
                    
                    // MARK: Relationship
                    NavigationLink(
                        destination: NoteCardFormRelationshipSelectionView(viewModel: relationshipViewModel),
                        isActive: $viewModel.isSelectingRelationship
                    ) {
                        HStack {
                            Image.noteCardRelationship
                                .frame(width: 20, height: 20, alignment: .center)
                                .foregroundColor(.primary)
                            Text("Links")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(viewModel.selectedRelationships.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onReceive(viewModel.$isSelectingRelationship, perform: handleRelationshipViewPushed)
                    
                    // MARK: Tag
                    NavigationLink(
                        destination: NoteCardFormTagSelectionView(formModel: viewModel),
                        isActive: $viewModel.isSelectingTag
                    ) {
                        HStack {
                            Image.noteCardTag
                                .frame(width: 20, height: 20, alignment: .center)
                                .foregroundColor(.primary)
                            Text("Tags")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(viewModel.selectedTags.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // MARK: Note
                    Button(action: beginEditNote) {
                        HStack {
                            Image.noteCardNote
                                .frame(width: 20, height: 20, alignment: .center)
                                .foregroundColor(.primary)
                            Text("Note")
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 3) { // markdown logo with sf symbol
                                Image(systemName: "m.square")
                                Image(systemName: "arrow.down.square")
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationBarItems(leading: cancelNavItem, trailing: commitNavItem)
            .navigationBarTitle(Text(viewModel.navigationTitle), displayMode: .inline)
            .sheet(item: $sheet, onDismiss: handleSheetDismissed, content: presentationSheet)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


// MARK: - Navigation Items

extension NoteCardForm {
    
    var cancelNavItem: some View {
        Button("Cancel", action: viewModel.onCancel ?? {})
            .disabled(viewModel.onCancel == nil)
    }
    
    var commitNavItem: some View {
        Button(action: viewModel.onCommit ?? {}) {
            Text(viewModel.commitTitle).bold()
        }
        .disabled(viewModel.onCommit == nil || !viewModel.canCommit)
    }
}


// MARK: - Sheet

extension NoteCardForm {
    
    enum Sheet: Identifiable {
        var id: Self { self }
        case note
    }
    
    func presentationSheet(for sheet: Sheet) -> some View {
        switch sheet {
        case .note:
            return ModalTextView(viewModel: $modalTextViewModel)
        }
    }
    
    func handleSheetDismissed() {
        if modalTextViewModel.onCommit != nil {
            viewModel.note = modalTextViewModel.text
        }
    }
}


// MARK: - Note

extension NoteCardForm {
    
    func beginEditNote() {
        modalTextViewModel.title = "Note"
        modalTextViewModel.text = viewModel.note
        
        modalTextViewModel.isFirstResponder = true
        modalTextViewModel.onCommit = commitEditNote
        
        sheet = .note
    }
    
    func commitEditNote() {
        viewModel.note = modalTextViewModel.text
        sheet = nil
    }
}


// MARK: - Relationship

extension NoteCardForm {
    
    func handleRelationshipViewPushed(_ isPushed: Bool) {
        if isPushed {
            beginEditRelationship()
        } else {
            commitEditRelationship()
        }
    }
    
    func handleRelationshipNoteCardSelected(_ noteCard: NoteCard) {
        if relationshipViewModel.borderedNoteCardIDs.contains(noteCard.uuid) {
            relationshipViewModel.borderedNoteCardIDs.remove(noteCard.uuid)
        } else {
            relationshipViewModel.borderedNoteCardIDs.insert(noteCard.uuid)
        }
        viewModel.onRelationshipSelected?(noteCard)
    }
    
    func beginEditRelationship() {
        relationshipViewModel.noteCards = viewModel.selectableRelationships
        relationshipViewModel.cellStyle = .short
        
        viewModel.selectedRelationships.forEach { noteCard in
            relationshipViewModel.borderedNoteCardIDs.insert(noteCard.uuid)
        }
    
        if let noteCard = viewModel.selectedNoteCard {
            relationshipViewModel.disableNoteCardIDs.insert(noteCard.uuid)
        }
        
        relationshipViewModel.onNoteCardSelected = handleRelationshipNoteCardSelected
    }
    
    func commitEditRelationship() {
        relationshipViewModel.noteCards = []
        relationshipViewModel.borderedNoteCardIDs = []
        relationshipViewModel.disableNoteCardIDs = []
        relationshipViewModel.onNoteCardSelected = nil
    }
}


struct NoteCardForm_Previews: PreviewProvider {
    static var previews: some View {
        NoteCardForm(viewModel: .init(collection: .sample))
    }
}