//
//  ConversationDataService.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import CoreData
import Foundation
import ProtonCore_Services

enum ConversationError: Error {
    case emptyConversationIDS
    case emptyLabel
}

protocol ConversationProvider: AnyObject {
    // MARK: - Collection fetching
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?)
    func fetchConversations(for labelID: String,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: ((Result<Void, Error>) -> Void)?)
    func fetchConversations(with conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Single item fetching
    func fetchConversation(with conversationID: String, includeBodyOf messageID: String?, callOrigin: String?, completion: ((Result<Conversation, Error>) -> Void)?)
    // MARK: - Operations
    func deleteConversations(with conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func markAsRead(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func markAsUnread(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?)
    func label(conversationIDs: [String],
               as labelID: String,
               isSwipeAction: Bool,
               completion: ((Result<Void, Error>) -> Void)?)
    func unlabel(conversationIDs: [String],
                 as labelID: String,
                 isSwipeAction: Bool,
                 completion: ((Result<Void, Error>) -> Void)?)
    func move(conversationIDs: [String],
              from previousFolderLabel: String,
              to nextFolderLabel: String,
              isSwipeAction: Bool,
              completion: ((Result<Void, Error>) -> Void)?)
    // MARK: - Clean up
    func cleanAll()
    // MARK: - Local for legacy reasons
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation]
}

final class ConversationDataService: Service, ConversationProvider {
    let apiService: APIService
    let userID: String
    let coreDataService: CoreDataService
    let labelDataService: LabelsDataService
    let lastUpdatedStore: LastUpdatedStoreProtocol
    private(set) weak var eventsService: EventsFetching?
    private weak var viewModeDataSource: ViewModeDataSource?
    private weak var queueManager: QueueManager?
    let undoActionManager: UndoActionManagerProtocol

    init(api: APIService,
         userID: String,
         coreDataService: CoreDataService,
         labelDataService: LabelsDataService,
         lastUpdatedStore: LastUpdatedStoreProtocol,
         eventsService: EventsFetching,
         undoActionManager: UndoActionManagerProtocol,
         viewModeDataSource: ViewModeDataSource?,
         queueManager: QueueManager?) {
        self.apiService = api
        self.userID = userID
        self.coreDataService = coreDataService
        self.labelDataService = labelDataService
        self.lastUpdatedStore = lastUpdatedStore
        self.eventsService = eventsService
        self.viewModeDataSource = viewModeDataSource
        self.queueManager = queueManager
        self.undoActionManager = undoActionManager
    }
}

// MARK: - Clean up
extension ConversationDataService {
    func cleanAll() {
        let context = coreDataService.rootSavingContext
        context.performAndWait {
            let conversationFetch = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
            conversationFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@", Conversation.Attributes.userID, self.userID, Conversation.Attributes.isSoftDeleted, NSNumber(false))
            if let conversations = try? context.fetch(conversationFetch) as? [NSManagedObject] {
                conversations.forEach { context.delete($0) }
            }

            let contextLabelFetch = NSFetchRequest<NSFetchRequestResult>(entityName: ContextLabel.Attributes.entityName)
            contextLabelFetch.predicate = NSPredicate(format: "%K == %@ AND %K == %@", ContextLabel.Attributes.userID, self.userID, ContextLabel.Attributes.isSoftDeleted, NSNumber(false))
            if let contextlabels = try? context.fetch(contextLabelFetch) as? [NSManagedObject] {
                contextlabels.forEach { context.delete($0) }
            }

            _ = context.saveUpstreamIfNeeded()
        }
    }
}

extension ConversationDataService {
    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Conversation.Attributes.entityName)
        fetchRequest.predicate = NSPredicate(format: "%K in %@", Conversation.Attributes.conversationID, selected)
        do {
            if let conversations = try context.fetch(fetchRequest) as? [Conversation] {
                return conversations
            }
        } catch {
        }
        return []
    }
}