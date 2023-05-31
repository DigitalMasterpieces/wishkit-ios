//
//  Configuraton.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 3/8/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

public struct Configuration {

    /// Hides/Shows the status badge of a wish e.g. "Approved" or "Implemented".
    public var statusBadge: Display

    public var localization: Localizaton

    public var buttons = Configuration.Buttons()

    public var tabBar = TabBar()

    init(
        showStatusBadge: Display = .hide,
        buttons: Configuration.Buttons = .init(),
        localization: Localizaton = .default()
    ) {
        self.statusBadge = showStatusBadge
        self.localization = localization
        self.buttons = buttons
    }
}

// MARK: - Display

extension Configuration {
    public enum Display {
        case show
        case hide
    }
}