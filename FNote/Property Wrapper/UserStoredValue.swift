//
//  UserStoredValue.swift
//  FNote
//
//  Created by Dara Beng on 1/30/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import Foundation
import SwiftUI


@propertyWrapper
struct UserStoredValue<Value> {
    
    // MARK: Property
    
    let storage: Storage
    
    let key: String
    
    let defaultValue: Value
    
    
    // MARK: Value
    
    var wrappedValue: Value {
        set { storage.setValue(newValue, forKey: key) }
        get { storage.value(forKey: key, defaultValue: defaultValue) }
    }
    
    var binding: Binding<Value> {
        .init(
            get: { self.storage.value(forKey: self.key, defaultValue: self.defaultValue) },
            set: { self.storage.setValue($0, forKey: self.key) }
        )
    }

    
    // MARK: Constructor
    
    init(in storage: Storage, key: String, defaultValue: Value) {
        self.storage = storage
        self.key = key
        self.defaultValue = defaultValue
    }
}


extension UserStoredValue {
    
    enum Storage {
        
        /// Store value in `UserDefaults`
        case userDefaults
        
        /// Store value in `NSUbiquitousKeyValueStore`
        /// - Important: Must enable iCloud's Key-value storage in Signing & Capabilities
        case iCloud
    }
}


extension UserStoredValue.Storage {
    
    func setValue(_ newValue: Value, forKey key: String) {
        let newValue = isValueOptionalAndNil(newValue) ? nil : newValue
        
        switch self {
        
        case .userDefaults:
            UserDefaults.standard.set(newValue, forKey: key)
            
        case .iCloud:
            let store = NSUbiquitousKeyValueStore.default
            store.set(newValue, forKey: key)
            store.synchronize()
        }
    }
    
    func value(forKey key: String, defaultValue: Value) -> Value {
        switch self {
        
        case .userDefaults:
            let value = UserDefaults.standard.object(forKey: key) as? Value
            return value ?? defaultValue
        
        case .iCloud:
            let value = NSUbiquitousKeyValueStore.default.object(forKey: key) as? Value
            return value ?? defaultValue
        }
    }
    
    /// Check if the value is of type `Optional` and its value is `nil`.
    ///
    /// - NOTE: Since `Value` can be optional type,
    /// use String(describing:) to check if it is `nil` (for now)
    ///
    /// - Parameter value: The value to check.
    /// 
    /// - Returns: `true` is the value is `nil`.
    func isValueOptionalAndNil(_ value: Value) -> Bool {
        String(describing: value) == "nil"
    }
}
