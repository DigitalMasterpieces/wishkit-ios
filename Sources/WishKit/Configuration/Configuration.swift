//
//  Configuraton.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 3/8/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

import Foundation
import WishKitShared

public struct Configuration {

    /// Hides/Shows the status badge of a wish e.g. "Approved" or "Implemented".
    public var statusBadge: StatusDisplay

    public var localization: Localization

    public var buttons = Configuration.Buttons()

    public var tabBar = TabBar()

    public var expandDescriptionInList: Bool = false

    public var dropShadow: Display = .show

    public var cornerRadius: CGFloat = 16

    public var emailField: EmailField = .optional

    /// Deactivates the `DetailWishView`, instead the description of the wish is expanded/shrunk by tapping on it.
    public var commentSection: Display = .show
    
    public var allowUndoVote: Bool = false

    /// Callback when a wish was successfully submitted
    public var onWishSubmitCallback: (() -> Void)?

    init(
        statusBadgeDisplay: StatusDisplay = .hide,
        localization: Localization = .default()
    ) {
        self.statusBadge = statusBadgeDisplay
        self.localization = localization
    }
}

// MARK: - Display

extension Configuration {
    public enum Display {
        case show
        case hide
    }

    public enum StatusDisplay {
        case show
        case hide
        case only(WishState)
    }
}

// MARK: - Email Field

extension Configuration {
    public enum EmailField {
        case none
        case optional
        case required
    }
}
