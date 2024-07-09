//
//  AddButton.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 3/8/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

import SwiftUI

struct AddButton: View {
    
    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var showingSheet = false

    private let size: CGSize

    private let buttonAction: () -> ()

    init(size: CGSize = CGSize(width: 45, height: 45), buttonAction: (() -> ())? = nil) {
        self.size = size
        self.buttonAction = buttonAction ?? { }
    }

    var body: some View {
        #if os(macOS) || os(visionOS)
            Button(action: buttonAction) {
                Image(systemName: "plus")
                    .frame(width: size.width, height: size.height)
                    .foregroundColor(addButtonTextColor)
            }
            .buttonStyle(.plain)
            .frame(width: size.width, height: size.height)
        #else
            VStack {
                Image(systemName: "plus")
                    .foregroundColor(addButtonTextColor)
            }
            .frame(width: size.width, height: size.height)
        #endif
    }

    var addButtonTextColor: Color {
        switch colorScheme {
        case .light:
            return WishKit.config.buttons.addButton.textColor.light
        case .dark:
            return WishKit.config.buttons.addButton.textColor.dark
        @unknown default:
            return WishKit.config.buttons.addButton.textColor.light
        }
    }
}

struct RoundButtonStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .foregroundColor(configuration.isPressed ? .white.opacity(0.66) : .white)
            .background(WishKit.theme.primaryColor)
            .brightness(configuration.isPressed ? 0.1 : 0.0)
            .clipShape(.circle)
            .shadow(color: .black.opacity(1/4), radius: 3, x: 0, y: 3)
    }
}

extension ButtonStyle where Self == RoundButtonStyle {
    static var roundButtonStyle: RoundButtonStyle {
        RoundButtonStyle()
    }
}
