import ProtonCore_UIFoundations

extension ConversationViewModel {

    func handleActionSheetAction(_ action: MessageViewActionSheetAction,
                                 message: Message,
                                 completion: @escaping () -> Void) {
        guard let messageLocation = message.orderedLocation?.rawValue else { return }
        switch action {
        case .markUnread:
            guard let index = messagesDataSource.firstIndex(where: { $0.message?.messageID == message.messageID }) else {
                return
            }
            self.shouldIgnoreUpdateOnce = true
            let indexPath = IndexPath(row: index, section: 1)
            conversationViewController?.cellTapped(messageId: message.messageID)
            messageService.mark(messages: [message], labelID: messageLocation, unRead: true)
            self.conversationViewController?.attemptAutoScroll(to: indexPath, position: .top)
        case .star:
            messageService.label(messages: [message], label: Message.Location.starred.rawValue, apply: true, shouldFetchEvent: true)
        case .unstar:
            messageService.label(messages: [message], label: Message.Location.starred.rawValue, apply: false, shouldFetchEvent: true)
        case .trash:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.trash.rawValue,
                                queue: true)
        case .archive:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.archive.rawValue,
                                queue: true)
        case .spam:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.spam.rawValue,
                                queue: true)
        case .delete:
            messageService.delete(messages: [message], label: messageLocation)
        case .reportPhishing:
            let messageBody = message.body
            BugDataService(api: self.user.apiService).reportPhishing(
                messageID: message.messageID,
                messageBody: messageBody) { _ in
                    self.messageService.move(messages: [message],
                                             from: [messageLocation],
                                             to: Message.Location.spam.rawValue,
                                             queue: true)
                    completion()
            }
            return
        case .inbox, .spamMoveToInbox:
            messageService.move(messages: [message],
                                from: [messageLocation],
                                to: Message.Location.inbox.rawValue,
                                queue: true)
        case .viewInDarkMode:
            guard let dataModel = self.messagesDataSource.first(where: { $0.message?.messageID == message.messageID }) else {
                break
            }
            dataModel.messageViewModel?.state.expandedViewModel?.messageContent.messageBodyViewModel.reloadMessageWith(style: .dark)
        case .viewInLightMode:
            guard let dataModel = self.messagesDataSource.first(where: { $0.message?.messageID == message.messageID }) else {
                break
            }
            dataModel.messageViewModel?.state.expandedViewModel?.messageContent.messageBodyViewModel.reloadMessageWith(style: .lightOnly)
        default:
            break
        }
        completion()
    }

}