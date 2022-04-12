//
//  ContactGroupSelectEmailViewModel.swift
//  ProtonMail - Created on 2018/8/27.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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


import Foundation

protocol ContactGroupSelectEmailViewModel
{
    var havingUnsavedChanges: Bool { get }
    func getSelectionStatus(at indexPath: IndexPath) -> Bool
    
    func getTotalEmailCount() -> Int
    func getCellData(at indexPath: IndexPath) -> (ID: String, name: String, email: String, isSelected: Bool)
    func save()
    
    func selectEmail(ID: String)
    func deselectEmail(ID: String)
    
    func search(query: String?)
}
