//
//  NSManagedObjectContext+Publisher.swift
//  Iron
//
//  Created by Karim Abou Zeid on 08.08.19.
//  Copyright © 2019 Karim Abou Zeid Software. All rights reserved.
//

import Foundation
import Combine
import CoreData
import os.log
import os.signpost

extension NSManagedObjectContext {
    public struct ObjectChanges {
        public let inserted: Set<NSManagedObject>
        public let updated: Set<NSManagedObject>
        public let deleted: Set<NSManagedObject>
    }
    
    private static let publisher: AnyPublisher<(ObjectChanges, NSManagedObjectContext), Never> = {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .compactMap { notification -> (ObjectChanges, NSManagedObjectContext)? in
                guard let userInfo = notification.userInfo else { return nil }
                guard let managedObjectContext = notification.object as? NSManagedObjectContext else { return nil }
                
                let signPostID = OSSignpostID(log: .coreDataMonitor)
                let signPostName: StaticString = "process MOC change notification"
                os_signpost(.begin, log: .coreDataMonitor, name: signPostName, signpostID: signPostID)
                defer { os_signpost(.end, log: .coreDataMonitor, name: signPostName, signpostID: signPostID) }

                let inserted = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let updated = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
                let deleted = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
                
                os_log("Received change notification inserted=%d updated=%d deleted=%d", log: .coreDataMonitor, type: .debug, inserted.count, updated.count, deleted.count)
                return (ObjectChanges(inserted: inserted, updated: updated, deleted: deleted), managedObjectContext)
            }
            .share()
            .eraseToAnyPublisher()
    }()
    
    public var publisher: AnyPublisher<ObjectChanges, Never> {
        Self.publisher
            .filter { $0.1 === self } // only publish changes belonging to this context
            .map { $0.0 }
            .eraseToAnyPublisher()
    }
}
