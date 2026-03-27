import SwiftUI

struct NotesTabContent: View {
    @StateObject private var notesStore = NotesStore()
    @State private var newNoteText = ""
    var inputFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack(spacing: 0) {
            
            ScrollView {
                VStack(spacing: 6) {
                    if notesStore.notes.isEmpty {
                        Text("No hay notas todavía")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                            .padding(.top, 20)
                    } else {
                        ForEach(notesStore.notes) { note in
                            NoteRow(note: note) {
                                notesStore.delete(note)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 110)
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(spacing: 8) {
                TextField("Nueva nota...", text: $newNoteText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .focused(inputFocused)
                    .onSubmit { saveNote() }
                
                Button(action: saveNote) {
                    Image(systemName: "return")
                        .foregroundColor(newNoteText.isEmpty ? .white.opacity(0.2) : .yellow)
                }
                .buttonStyle(.plain)
                .disabled(newNoteText.isEmpty)
            }
            .frame(height: 44)
            .padding(.horizontal, 16)
            
        }
    }
    
    func saveNote() {
        guard !newNoteText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        notesStore.add(newNoteText)
        newNoteText = ""
    }
}

// ← NoteRow movido aquí desde NotchContentView
struct NoteRow: View {
    let note: Note
    let onDelete: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.yellow.opacity(0.7))
                .frame(width: 6, height: 6)
            Text(note.text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(2)
            Spacer()
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isHovering ? 0.08 : 0.04))
        )
        .onHover { isHovering = $0 }
    }
}
