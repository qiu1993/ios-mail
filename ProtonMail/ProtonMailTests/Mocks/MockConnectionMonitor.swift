// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import Network
@testable import ProtonMail

@available(iOS 12.0, *)
class MockConnectionMonitor: ConnectionMonitor {
    var currentNWPath: NWPath? {
        return nil
    }

    var pathUpdateHandler: ((NWPath) -> Void)?

    func start(queue: DispatchQueue) {

    }

    func cancel() {

    }
}