//
//  TemporaryHacks.swift
//  ProtonCore-HumanVerification - Created on 25/10/2021.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if canImport(AppKit)
import AppKit.NSImage

typealias ImageType = NSImage

extension ImageType {
    static func imageInHumanVerificationBundle(named resourceName: String) -> ImageType {
        HVCommon.bundle.image(forResource: resourceName)!
    }
}

#elseif canImport(UIKit)
import UIKit.UIImage

typealias ImageType = UIImage

extension ImageType {
    static func imageInHumanVerificationBundle(named: String) -> ImageType {
        ImageType(named: named, in: HVCommon.bundle, compatibleWith: nil)!
    }
}

#endif
