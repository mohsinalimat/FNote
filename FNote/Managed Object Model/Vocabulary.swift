//
//  Vocabulary+CoreDataClass.swift
//  FNote
//
//  Created by Dara Beng on 1/20/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//
//

import CloudKit
import CoreData


public class Vocabulary: NSManagedObject, LocalRecord {
    
    var recordType: CKRecord.RecordType { return "Vocabulary" }
    var recordZone: CKRecordZone { return CloudKitService.ckVocabularyCollectionZone }

    @NSManaged private(set) var recordMetadata: RecordMetadata
    @NSManaged public var native: String
    @NSManaged public var translation: String
    @NSManaged public var note: String
    @NSManaged public var isFavorited: Bool
    @NSManaged private var politenessValue: Int64
    @NSManaged private(set) var collection: VocabularyCollection
    @NSManaged private(set) var relations: Set<Vocabulary>
    @NSManaged private(set) var alternatives: Set<Vocabulary>
    @NSManaged private(set) var connections: Set<VocabularyConnection>
    @NSManaged private(set) var tags: Set<Tag>
    
    @NSManaged private(set) var sourceOf: Set<VocabularyConnection>
    @NSManaged private(set) var targetOf: Set<VocabularyConnection>
    
    var politeness: Politeness {
        set { politenessValue = Int64(newValue.rawValue) }
        get { return Politeness(rawValue: Int(politenessValue)) ?? .undecided }
    }
    
    
    convenience init(collection: VocabularyCollection) {
        let context = collection.managedObjectContext!
        self.init(context: context)
        self.collection = collection
        native = ""
        translation = ""
        note = ""
        politeness = .undecided
        relations = []
        alternatives = []
        tags = []
        connections = []
        recordMetadata = RecordMetadata(recordType: recordType, recordName: nil, zone: recordZone, context: context)
        #warning("TODO: set collection and reconfigure its CKRecord")
    }
    
    func tagNames() -> [String] {
        return tags.map({ $0.name })
    }
}


extension Vocabulary {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vocabulary> {
        return NSFetchRequest<Vocabulary>(entityName: "Vocabulary")
    }
    
    func recordValuesForServerKeys() -> [String : Any] {
        return [
            Key.native.stringValue: native,
            Key.translation.stringValue: translation,
            Key.note.stringValue: note,
            Key.politeness.stringValue: politeness
        ]
    }
    
    enum Key: LocalRecord.DatabaseKey {
        case native
        case translation
        case note
        case politeness
        case relations
        case alternatives
    }
    
    /// Vocabulary politeness value.
    /// - warning: These values should not be changed because they must be matched with the database.
    enum Politeness: LocalRecord.DatabaseIntegerEnum, CaseIterable {
        case undecided
        case informal
        case neutral
        case formal
        
        var string: String {
            switch self {
            case .undecided: return "Undecided"
            case .informal: return "Informal"
            case .neutral: return "Neutral"
            case .formal: return "Formal"
            }
        }
        
        var abbreviation: String {
            switch self {
            case .undecided: return "U"
            case .informal: return "I"
            case .neutral: return "N"
            case .formal: return "F"
            }
        }
    }
}


extension Vocabulary {
    
    /// Add connection between the given vocabulary and create a connection object.
    /// - returns: The `VocabularyConnection` created.
    func addConnection(with vocabulary: Vocabulary, type: VocabularyConnection.ConnectionType) -> VocabularyConnection {
        switch type {
        case .related:
            self.relations.insert(vocabulary)
            vocabulary.relations.insert(self)
        case .alternative:
            self.alternatives.insert(vocabulary)
            vocabulary.alternatives.insert(self)
        }
        
        let connection = VocabularyConnection(type: type, source: self, target: vocabulary)
        connections.insert(connection)
        return connection
    }
    
    /// Remove the connection between the given vocabulary and delete the connection object.
    /// - returns: The deleted `VocabularyConnection` if the connections was removed. Otherwise, `nil`.
    func removeConnection(with vocabulary: Vocabulary, type: VocabularyConnection.ConnectionType) -> VocabularyConnection? {
        guard let connection = connections.first(where: { $0.type == type && $0.isConnection(of: self, and: vocabulary) }) else { return nil }
        switch type {
        case .related:
            self.relations.remove(vocabulary)
            vocabulary.relations.remove(self)
            managedObjectContext?.delete(connection)
            return connection
        case .alternative:
            self.alternatives.remove(vocabulary)
            vocabulary.alternatives.remove(self)
            managedObjectContext?.delete(connection)
            return connection
        }
    }
    
    /// Create and add the new tag to the vocabulary's tags.
    /// If the given new name already exists in user's tags, no tag is created.
    /// - returns: The added tag if the tag is added. Otherwise, `nil`.
    @discardableResult
    func addTag(newName: String, colorHex: String?) -> Tag? {
        guard collection.user.tags.contains(where: { $0.name == newName }) == false else { return nil }
        let newTag = Tag(name: newName, colorHex: colorHex, user: collection.user)
        tags.insert(newTag)
        return newTag
    }
    
    /// Add an existing tag to the vocabulary's tags.
    /// - returns: The added tag if exists. Otherwise, `nil`.
    @discardableResult
    func addTag(existingName: String) -> Tag? {
        guard let existingTag = collection.user.tags.first(where: { $0.name == existingName }) else { return nil }
        tags.insert(existingTag)
        return existingTag
    }
    
    @discardableResult
    func removeTag(name: String) -> Tag? {
        guard let tag = tags.first(where: { $0.name == name }) else { return nil }
        tags.remove(tag)
        return tag
    }
}


extension Vocabulary {
    
    static func hasChanges(before: Vocabulary, after: Vocabulary) -> Bool {
        return after.isFavorited != before.isFavorited
            || after.politeness != before.politeness
            || after.translation != before.translation
            || after.native != before.native
            || after.note != before.note
            || after.tags.count != before.tags.count
            || Set(after.tagNames()).isSubset(of: before.tagNames()) != true
    }
}
