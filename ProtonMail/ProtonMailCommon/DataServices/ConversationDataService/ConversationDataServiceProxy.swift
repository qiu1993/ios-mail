//
//  ConversationDataServiceProxy.swift
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

final class ConversationDataServiceProxy: ConversationProvider {
    let apiService: APIService
    let userID: String
    let coreDataService: CoreDataService
    let labelDataService: LabelsDataService
    let lastUpdatedStore: LastUpdatedStoreProtocol
    private(set) weak var eventsService: EventsFetching?
    private weak var viewModeDataSource: ViewModeDataSource?
    private weak var queueManager: QueueManager?
    let conversationDataService: ConversationDataService
    private lazy var localConversationUpdater = LocalConversationUpdater(userID: userID)

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
        self.conversationDataService = ConversationDataService(api: apiService,
                                                               userID: userID,
                                                               coreDataService: coreDataService,
                                                               labelDataService: labelDataService,
                                                               lastUpdatedStore: lastUpdatedStore,
                                                               eventsService: eventsService,
                                                               undoActionManager: undoActionManager,
                                                               viewModeDataSource: viewModeDataSource,
                                                               queueManager: queueManager)
    }
}

private extension ConversationDataServiceProxy {
    func updateContextLabels(for conversationIDs: [String], on context: NSManagedObjectContext) {
        let conversations = fetchLocalConversations(withIDs: NSMutableSet(array: conversationIDs), in: context)
        conversations.forEach { conversation in
            (conversation.labels as? Set<ContextLabel>)?
                .forEach {
                    context.refresh(conversation, mergeChanges: true)
                    context.refresh($0, mergeChanges: true)
                }
        }
    }
}

extension ConversationDataServiceProxy {
    func fetchConversationCounts(addressID: String?, completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversationCounts(addressID: addressID, completion: completion)
    }

    func fetchConversations(for labelID: String,
                            before timestamp: Int,
                            unreadOnly: Bool,
                            shouldReset: Bool,
                            completion: ((Result<Void, Error>) -> Void)?) {
        conversationDataService.fetchConversations(for: labelID,
                                                   before: timestamp,
                                                   unreadOnly: unreadOnly,
                                                   shouldReset: shouldReset,
                                                   completion: completion)
    }

    func fetchConversations(with conversationIDs: [String], completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        conversationDataService.fetchConversations(with: conversationIDs, completion: completion)
    }

    func fetchConversation(with conversationID: String,
                           includeBodyOf messageID: String?,
                           callOrigin: String?,
                           completion: ((Result<Conversation, Error>) -> Void)?) {
        conversationDataService.fetchConversation(with: conversationID,
                                                  includeBodyOf: messageID,
                                                  callOrigin: "ConversationDataServiceProxy",
                                                  completion: completion)
    }

    func deleteConversations(with conversationIDs: [String],
                             labelID: String,
                             completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.delete(currentLabelID: labelID, itemIDs: conversationIDs), isConversation: true)
        localConversationUpdater.delete(conversationIDs: conversationIDs,
                                        in: coreDataService.operationContext) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.coreDataService.mainContext)
            completion?(result)
        }
    }

    func markAsRead(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.read(itemIDs: conversationIDs, objectIDs: []), isConversation: true)
        localConversationUpdater.mark(conversationIDs: conversationIDs,
                                      in: coreDataService.operationContext,
                                      asUnread: false,
                                      labelID: labelID) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.coreDataService.mainContext)
            completion?(result)
        }
    }

    func markAsUnread(conversationIDs: [String], labelID: String, completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.unread(currentLabelID: labelID, itemIDs: conversationIDs, objectIDs: []), isConversation: true)
        localConversationUpdater.mark(conversationIDs: conversationIDs,
                                      in: coreDataService.operationContext,
                                      asUnread: true,
                                      labelID: labelID) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.coreDataService.mainContext)
            completion?(result)
        }
    }

    func label(conversationIDs: [String],
               as labelID: String,
               isSwipeAction: Bool,
               completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.label(currentLabelID: labelID,
                          shouldFetch: nil,
                          isSwipeAction: isSwipeAction,
                          itemIDs: conversationIDs,
                          objectIDs: []),
                   isConversation: true)
        localConversationUpdater.editLabels(conversationIDs: conversationIDs,
                                            in: coreDataService.operationContext,
                                            labelToRemove: nil,
                                            labelToAdd: labelID,
                                            isFolder: false) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.coreDataService.mainContext)
            completion?(result)
        }
    }

    func unlabel(conversationIDs: [String],
                 as labelID: String,
                 isSwipeAction: Bool,
                 completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.unlabel(currentLabelID: labelID,
                            shouldFetch: nil,
                            isSwipeAction: isSwipeAction,
                            itemIDs: conversationIDs,
                            objectIDs: []),
                   isConversation: true)
        localConversationUpdater.editLabels(conversationIDs: conversationIDs,
                                            in: coreDataService.operationContext,
                                            labelToRemove: labelID,
                                            labelToAdd: nil,
                                            isFolder: false) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.coreDataService.mainContext)
            completion?(result)
        }
    }

    func move(conversationIDs: [String],
              from previousFolderLabel: String,
              to nextFolderLabel: String,
              isSwipeAction: Bool,
              completion: ((Result<Void, Error>) -> Void)?) {
        guard !conversationIDs.isEmpty else {
            completion?(.failure(ConversationError.emptyConversationIDS))
            return
        }
        self.queue(.folder(nextLabelID: nextFolderLabel,
                           shouldFetch: true,
                           isSwipeAction: isSwipeAction,
                           itemIDs: conversationIDs,
                           objectIDs: []),
                   isConversation: true)
        localConversationUpdater.editLabels(conversationIDs: conversationIDs,
                                            in: coreDataService.operationContext,
                                            labelToRemove: previousFolderLabel,
                                            labelToAdd: nextFolderLabel,
                                            isFolder: true) { [weak self] result in
            guard let self = self else { return }
            self.updateContextLabels(for: conversationIDs, on: self.coreDataService.mainContext)
            completion?(result)
        }
    }

    func cleanAll() {
        conversationDataService.cleanAll()
    }

    func fetchLocalConversations(withIDs selected: NSMutableSet, in context: NSManagedObjectContext) -> [Conversation] {
        conversationDataService.fetchLocalConversations(withIDs: selected, in: context)
    }
}

extension ConversationDataServiceProxy {
    private func queue(_ action: MessageAction, isConversation: Bool) {
        let task = QueueManager.Task(messageID: "",
                                     action: action,
                                     userID: self.userID,
                                     dependencyIDs: [],
                                     isConversation: isConversation)
        _ = self.queueManager?.addTask(task)
    }
}