//
//  SwipeActionRightToLeftTableViewCell.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class SwipeActionRightToLeftTableViewCell: UITableViewCell {
    @IBOutlet private weak var messageCellView: UIView!
    @IBOutlet private weak var swipeActionIconView: UIImageView!
    @IBOutlet private weak var swipeActionColorView: UIView!
    @IBOutlet private weak var swipeActionTitleLabel: UILabel!

    @IBOutlet private weak var squareView: UIView!
    @IBOutlet private weak var topPlaceholderView: UIView!
    @IBOutlet private weak var middlePlaceholderView: UIView!
    @IBOutlet private weak var lastPlaceholderView: UIView!

    static var CellID: String {
        return "\(self)"
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.contentView.backgroundColor = ColorProvider.BackgroundSecondary
        swipeActionColorView.setCornerRadius(radius: 8)
        messageCellView.backgroundColor = ColorProvider.BackgroundNorm
        messageCellView.setCornerRadius(radius: 8)

        squareView.backgroundColor = ColorProvider.BackgroundSecondary
        topPlaceholderView.backgroundColor = ColorProvider.BackgroundSecondary
        middlePlaceholderView.backgroundColor = ColorProvider.BackgroundSecondary
        lastPlaceholderView.backgroundColor = ColorProvider.BackgroundSecondary
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        swipeActionIconView.isHidden = false
        swipeActionIconView.image = nil
        swipeActionTitleLabel.text = nil
        swipeActionColorView.backgroundColor = .white
    }

    func configure(icon: UIImage, title: String, color: UIColor, shouldHideIcon: Bool = false) {
        if shouldHideIcon {
            swipeActionIconView.isHidden = true
        } else {
            swipeActionIconView.isHidden = false
            swipeActionIconView.image = icon
        }
        var attribute = FontManager.CaptionStrong.alignment(.center).addTruncatingTail()
        attribute[.foregroundColor] = ColorProvider.TextInverted
        swipeActionTitleLabel.attributedText = title.apply(style: attribute)
        swipeActionIconView.tintColor = ColorProvider.TextInverted
        swipeActionColorView.backgroundColor = color
    }
}
