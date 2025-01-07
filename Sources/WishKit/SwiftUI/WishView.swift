//
//  WishView.swift
//  wishkit-ios
//
//  Created by Martin Lasek on 8/12/23.
//  Copyright © 2023 Martin Lasek. All rights reserved.
//

import SwiftUI
import WishKitShared

struct WishView: View {

    // Helps differentiate where this view is used (in the list or in detail view).
    enum ViewKind {
        case list
        case detail
    }

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject
    private var alertModel = AlertModel()

    @Binding
    private var voteCount: Int

    private let wishResponse: WishResponse

    private let voteActionCompletion: () -> Void

    private let viewKind: ViewKind

    private var descriptionLineLimit: Int? {
        if viewKind == .detail {
            return nil
        }
        
        return self.isExpanded ? nil : 1
    }

    @State private var isExpanded = WishKit.config.expandDescriptionInList

    init(wishResponse: WishResponse, viewKind: ViewKind, voteActionCompletion: @escaping (() -> Void)) {
        self.wishResponse = wishResponse
        self.viewKind = viewKind
        self.voteActionCompletion = voteActionCompletion
        self._voteCount = .constant(wishResponse.votingUsers.count)
    }

    var body: some View {
        HStack(spacing: 0) {
            Button(action: voteAction) {
                VStack(spacing: 5) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .imageScale(.medium)
                        .foregroundColor(arrowColor)
                    Text(String(describing: voteCount))
                        .font(.headline)
                        .foregroundColor(textColor)
                        .frame(width: 45)
                }
                .padding([.leading, .trailing], 12)
                .cornerRadius(12)
            }
            .buttonStyle(.plain) // makes sure it looks good on macOS.
            .alert(isPresented: $alertModel.showAlert) {
                var title = Text(WishKit.config.localization.youCanNotVoteForYourOwnWish)
                switch alertModel.alertReason {
                case .alreadyVoted:
                    title = Text(WishKit.config.localization.youCanOnlyVoteOnce)
                case .alreadyImplemented:
                    title = Text(WishKit.config.localization.youCanNotVoteForAnImplementedWish)
                case .voteReturnedError(let error):
                    title = Text("Something went wrong during your vote. Try again later.\n\n\(error)")
                case .none:
                    title = Text(WishKit.config.localization.youCanNotVoteForYourOwnWish)
                default:
                    title = Text("Something went wrong during your vote. Try again later.")
                }

                return Alert(title: title)
            }

            VStack(spacing: 5) {
                HStack {
                    Text(wishResponse.title)
                        .foregroundColor(textColor)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .lineLimit(viewKind == .list ? 1 : nil)

                    Spacer()

                    if viewKind == .list && WishKit.config.statusBadge == .show {
                        Text(wishResponse.state.description.uppercased())
                            .opacity(0.8)
                            .font(.system(size: 10, weight: .medium))
                            .padding(EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5))
                            .foregroundColor(.primary)
                            .background(badgeColor(for: wishResponse.state).opacity(1/3))
                            .cornerRadius(6)
                    }
                }

                HStack {
                    Text(wishResponse.description)
                        .foregroundColor(textColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(descriptionLineLimit)
                        // By changing the id, the view is identified as a new view and we avoid the weird text animation.
                        .id(wishResponse.id.uuidString + String(self.isExpanded))
                    Spacer()
                }
            }
        }
        .padding([.top, .bottom, .trailing], 10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: WishKit.config.cornerRadius, style: .continuous))
        .wkShadow()
        .onTapGesture {
            withAnimation(.spring) {
                self.isExpanded.toggle()
            }
        }
    }

    func badgeColor(for wishState: WishState) -> Color {
        switch wishState {
        case .approved:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.approved.light
            case .dark:
                return WishKit.theme.badgeColor.approved.dark
            @unknown default:
                return WishKit.theme.badgeColor.approved.light
            }
        case .implemented:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.implemented.light
            case .dark:
                return WishKit.theme.badgeColor.implemented.dark
            @unknown default:
                return WishKit.theme.badgeColor.implemented.light
            }

        case .pending:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.pending.light
            case .dark:
                return WishKit.theme.badgeColor.pending.dark
            @unknown default:
                return WishKit.theme.badgeColor.pending.light
            }
        case .inReview:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.inReview.light
            case .dark:
                return WishKit.theme.badgeColor.inReview.dark
            @unknown default:
                return WishKit.theme.badgeColor.inReview.light
            }
        case .planned:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.planned.light
            case .dark:
                return WishKit.theme.badgeColor.planned.dark
            @unknown default:
                return WishKit.theme.badgeColor.planned.light
            }
        case .inProgress:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.inProgress.light
            case .dark:
                return WishKit.theme.badgeColor.inProgress.dark
            @unknown default:
                return WishKit.theme.badgeColor.inProgress.light
            }

        case .completed:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.completed.light
            case .dark:
                return WishKit.theme.badgeColor.completed.dark
            @unknown default:
                return WishKit.theme.badgeColor.completed.light
            }
        case .rejected:
            switch colorScheme {
            case .light:
                return WishKit.theme.badgeColor.rejected.light
            case .dark:
                return WishKit.theme.badgeColor.rejected.dark
            @unknown default:
                return WishKit.theme.badgeColor.rejected.light
            }
        default:
            return .black
        }
    }

    private func voteAction() {
        if wishResponse.state == .implemented {
            alertModel.alertReason = .alreadyImplemented
            alertModel.showAlert = true
            return
        }
        
        let userUUID = UUIDManager.getUUID()
        
        let hasVoted = wishResponse.votingUsers.contains(where: { user in user.uuid == userUUID })
        
        if (hasVoted) && WishKit.config.allowUndoVote == false {
            alertModel.alertReason = .alreadyVoted
            alertModel.showAlert = true
            return
        }

        let request = VoteWishRequest(wishId: wishResponse.id)
        
        WishApi.voteWish(voteRequest: request) { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    voteActionCompletion()
                }
            case .failure(let error):
                alertModel.alertReason = .voteReturnedError(error.localizedDescription)
                alertModel.showAlert = true
            }
        }
    }
}

// MARK: - Darkmode

extension WishView {
    var arrowColor: Color {
        let userUUID = UUIDManager.getUUID()
        if wishResponse.votingUsers.contains(where: { user in user.uuid == userUUID }) {
            return WishKit.theme.primaryColor
        }

        switch colorScheme {
        case .light:
            return WishKit.config.buttons.voteButton.arrowColor.light
        case .dark:
            return WishKit.config.buttons.voteButton.arrowColor.dark
        @unknown default:
            return WishKit.config.buttons.voteButton.arrowColor.light
        }
    }

    var textColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.textColor {
                return color.light
            }

            return .black
        case .dark:
            if let color = WishKit.theme.textColor {
                return color.dark
            }

            return .white
        @unknown default:
            if let color = WishKit.theme.textColor {
                return color.light
            }

            return .black
        }
    }

    var backgroundColor: Color {
        switch colorScheme {
        case .light:

            if let color = WishKit.theme.secondaryColor {
                return color.light
            }

            return PrivateTheme.elementBackgroundColor.light
        case .dark:
            if let color = WishKit.theme.secondaryColor {
                return color.dark
            }

            return PrivateTheme.elementBackgroundColor.dark
        @unknown default:
            if let color = WishKit.theme.secondaryColor {
                return color.light
            }

            return PrivateTheme.elementBackgroundColor.light
        }
    }
}
