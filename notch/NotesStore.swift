//
//  NotesStore.swift
//  notch
//
//  Created by Alba Costas Fernández on 23/3/26.
//
import Foundation
import Combine

struct Note: Identifiable, Codable {
    let id: UUID
    var text: String
    let createdAt: Date
    
    init(text: String) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
    }
}

class NotesStore: ObservableObject {
    
    @Published var notes: [Note] = []
    private let saveKey = "quick_notes_data"
    
    init() { load() }
    
    func add(_ text: String) {
        let note = Note(text: text)
        notes.insert(note, at: 0) // Las más recientes primero
        save()
        syncToAppleNotes(text)
    }
    
    func delete(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
}

func syncToAppleNotes(_ text: String) {
    let script = """
    tell application "Notes"
        tell account "iCloud"
            make new note at folder "Quick Notch" with properties {name:"\(text)", body:"\(text)"}
        end tell
    end tell
    """
    
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: script) {
        scriptObject.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript error: \(error)")
        }
    }
}

