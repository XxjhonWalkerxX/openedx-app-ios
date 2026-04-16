//
//  EditProfileView.swift
//  Profile
//
//  Created by  Stepanok Ivan on 26.11.2022.
//

import SwiftUI
import Core
import OEXFoundation
import Theme

private enum EditProfileLayout {
    static let horizontalPadding: CGFloat = 24
    static let headerTopPadding: CGFloat = 14
    static let headerBottomPadding: CGFloat = 10
    static let headerSidePadding: CGFloat = 20
    static let headerButtonSize: CGFloat = 44
    static let avatarSize: CGFloat = 104
    static let avatarBadgeSize: CGFloat = 34
    static let avatarBadgeOffsetX: CGFloat = 34
    static let avatarBadgeOffsetY: CGFloat = 42
    static let summarySpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let fieldSpacing: CGFloat = 18
    static let contentTopPadding: CGFloat = 10
    static let contentBottomPadding: CGFloat = 48
}

public struct EditProfileView: View {
    
    @ObservedObject public var viewModel: EditProfileViewModel
    @State private var showingImagePicker = false
    @State private var showingBottomSheet = false
    
    public init(
        viewModel: EditProfileViewModel,
        avatar: UIImage?,
        profileDidEdit: @escaping ((UserProfile?, UIImage?)) -> Void
    ) {
        self.viewModel = viewModel
        self.viewModel.profileDidEdit = profileDidEdit
        self.viewModel.inputImage = avatar
        self.viewModel.oldAvatar = avatar
        self.viewModel.loadLocationsAndSpokenLanguages()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Theme.Colors.brandCream
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topHeader

                    ScrollView {
                        VStack(spacing: EditProfileLayout.sectionSpacing) {
                            profileSummary

                            VStack(alignment: .leading, spacing: EditProfileLayout.fieldSpacing) {
                                PickerView(
                                    config: viewModel.yearsConfiguration,
                                    router: viewModel.router
                                )

                                if viewModel.isEditable {
                                    PickerView(
                                        config: viewModel.countriesConfiguration,
                                        router: viewModel.router
                                    )

                                    PickerView(
                                        config: viewModel.spokenLanguageConfiguration,
                                        router: viewModel.router
                                    )

                                    VStack(alignment: .leading, spacing: 10) {
                                        Text(ProfileLocalization.Edit.Fields.aboutMe)
                                            .font(Theme.Fonts.titleMedium)
                                            .foregroundColor(Theme.Colors.textPrimary)
                                            .accessibilityIdentifier("about_text")

                                        TextEditor(text: $viewModel.profileChanges.shortBiography)
                                            .font(Theme.Fonts.bodyMedium)
                                            .foregroundColor(Theme.Colors.textInputTextColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .frame(height: 200)
                                            .scrollContentBackground(.hidden)
                                            .background(
                                                Theme.Shapes.textInputShape
                                                    .fill(Theme.Colors.textInputBackground)
                                            )
                                            .overlay(
                                                Theme.Shapes.textInputShape
                                                    .stroke(lineWidth: 1)
                                                    .fill(Theme.Colors.textInputStroke)
                                            )
                                            .accessibilityIdentifier("short_bio_textarea")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, EditProfileLayout.horizontalPadding)
                        .padding(.top, EditProfileLayout.contentTopPadding)
                        .padding(.bottom, EditProfileLayout.contentBottomPadding)
                        .onReceive(
                            viewModel.yearsConfiguration.$text.combineLatest(
                                viewModel.countriesConfiguration.$text,
                                viewModel.spokenLanguageConfiguration.$text
                            ),
                            perform: { _ in
                                viewModel.checkChanges()
                                viewModel.checkProfileType()
                            }
                        )
                        .onChange(of: viewModel.profileChanges) { _ in
                            viewModel.checkChanges()
                            viewModel.checkProfileType()
                        }
                        .onChange(of: viewModel.profileChanges.shortBiography, perform: { bio in
                            if bio.count > 300 {
                                viewModel.profileChanges.shortBiography.removeLast()
                            }
                        })
                    }
                    .frameLimit(width: proxy.size.width)
                    .scrollIndicators(.hidden)
                    .sheet(isPresented: $showingImagePicker) {
                        ImagePickerView(image: $viewModel.inputImage)
                            .ignoresSafeArea()
                    }
                    .onChange(of: showingImagePicker, perform: { value in
                        if !value {
                            if let image = viewModel.inputImage {
                                viewModel.profileChanges.isAvatarChanged = true
                                viewModel.resizeImage(image: image, longSideSize: 500)
                            }
                        }
                    })
                    .onRightSwipeGesture {
                        viewModel.backButtonTapped()
                    }
                    .scrollAvoidKeyboard(dismissKeyboardByTap: true)
                    .ignoresSafeArea(edges: .bottom)
                }
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .navigationTitle(ProfileLocalization.editProfile)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EmptyView()
                    }
                }

                if viewModel.showError {
                    VStack {
                        Spacer()
                        SnackBarView(message: viewModel.errorMessage)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
                }

                if viewModel.showAlert {
                    VStack(alignment: .center) {
                        Spacer()
                        HStack(alignment: .top, spacing: 6) {
                            CoreAssets.alarm.swiftUIImage.renderingMode(.template)
                            Text(viewModel.alertMessage ?? "")
                                .font(Theme.Fonts.labelLarge)
                        }
                        .shadowCardStyle(bgColor: Theme.Colors.warning, textColor: .black)
                        .transition(.move(edge: .bottom))
                        .onAppear {
                            doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                                viewModel.alertMessage = nil
                            }
                        }
                    }
                }

                ProfileBottomSheet(
                    showingBottomSheet: $showingBottomSheet,
                    openGallery: {
                        showingImagePicker = true
                        withAnimation {
                            showingBottomSheet = false
                        }
                    },
                    removePhoto: {
                        viewModel.inputImage = CoreAssets.noAvatar.image
                        viewModel.profileChanges.isAvatarDeleted = true
                        showingBottomSheet = false
                    }
                )

                if viewModel.isShowProgress {
                    ProgressBar(size: 40, lineWidth: 8)
                        .padding(.top, 150)
                        .padding(.horizontal)
                        .accessibilityIdentifier("progress_bar")
                }
            }
            .onFirstAppear {
                viewModel.checkProfileType()
                viewModel.checkChanges()
                viewModel.trackScreenEvent()
            }
        }
    }

    private var topHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                viewModel.backButtonTapped()
            }) {
                CoreAssets.arrowLeft.swiftUIImage
                    .renderingMode(.template)
                    .foregroundColor(Theme.Colors.brandGreen)
                    .frame(width: EditProfileLayout.headerButtonSize, height: EditProfileLayout.headerButtonSize)
            }
            .accessibilityIdentifier("back_button")

            Spacer(minLength: 0)

            Text(ProfileLocalization.editProfile)
                .font(Theme.Fonts.ttRoundsCompressedMedium(28))
                .foregroundColor(Theme.Colors.brandGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Button(action: {
                if viewModel.isChanged {
                    Task {
                        viewModel.trackProfileEditDoneClicked()
                        await viewModel.saveProfileUpdates()
                    }
                }
            }, label: {
                HStack(spacing: 4) {
                    CoreAssets.done.swiftUIImage.renderingMode(.template)
                        .foregroundColor(Theme.Colors.brandGreen)
                    Text(CoreLocalization.done)
                        .font(Theme.Fonts.labelLarge)
                        .foregroundColor(Theme.Colors.brandGreen)
                }
            })
            .opacity(viewModel.isChanged ? 1 : 0.3)
            .accessibilityIdentifier("done_button")
        }
        .padding(.horizontal, EditProfileLayout.headerSidePadding)
        .padding(.top, EditProfileLayout.headerTopPadding)
        .padding(.bottom, EditProfileLayout.headerBottomPadding)
        .background(Theme.Colors.brandCream)
    }

    private var profileSummary: some View {
        VStack(spacing: EditProfileLayout.summarySpacing) {
            Text(viewModel.profileChanges.profileType.localizedValue.capitalized)
                .font(Theme.Fonts.titleSmall)
                .foregroundColor(Theme.Colors.textSecondary)
                .accessibilityIdentifier("profile_type_text")

            Button(
                action: {
                    withAnimation {
                        showingBottomSheet.toggle()
                    }
                },
                label: {
                    UserAvatar(
                        url: viewModel.profileChanges.profileType == .full
                        ? viewModel.userModel.avatarUrl
                        : "",
                        image: viewModel.profileChanges.profileType == .full
                        ? $viewModel.inputImage
                        : .constant(nil),
                        size: EditProfileLayout.avatarSize,
                        borderColor: Theme.Colors.brandCardPrimary
                    )
                    .overlay(
                        ZStack {
                            Circle()
                                .frame(width: EditProfileLayout.avatarBadgeSize, height: EditProfileLayout.avatarBadgeSize)
                                .foregroundColor(Theme.Colors.brandGreen)
                            CoreAssets.addPhoto.swiftUIImage.renderingMode(.template)
                                .foregroundColor(Theme.Colors.white)
                        }
                        .offset(
                            x: EditProfileLayout.avatarBadgeOffsetX,
                            y: EditProfileLayout.avatarBadgeOffsetY
                        )
                        .saturation(viewModel.canEditAvatar ? 1.0 : 0)
                    )
                    .padding(.top, 18)
                }
            )
            .disabled(!viewModel.canEditAvatar)
            .accessibilityIdentifier("change_profile_image_button")

            Text(displayNameText.uppercased())
                .font(Theme.Fonts.ttRoundsCompressedMedium(32))
                .foregroundColor(Theme.Colors.brandGreen)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("username_text")

            Button(
                ProfileLocalization.switchTo + " " + viewModel.profileChanges.profileType.switchToButtonTitle,
                action: {
                    viewModel.switchProfile()
                    viewModel.checkProfileType()
                    viewModel.checkChanges()
                }
            )
            .font(Theme.Fonts.titleMedium)
            .foregroundColor(Theme.Colors.brandGreen)
            .accessibilityIdentifier("switch_profile_button")
        }
        .frame(maxWidth: .infinity)
    }

    private var displayNameText: String {
        let trimmedName = viewModel.userModel.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return viewModel.userModel.username
        }
        return trimmedName
    }
}

#if DEBUG
struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let userModel = UserProfile(
            avatarUrl: "",
            name: "Peter Parket",
            username: "Peter",
            dateJoined: Date(),
            yearOfBirth: 0,
            country: "Ukraine",
            shortBiography: "",
            isFullProfile: true,
            email: "peter@example.org"
        )
        
        EditProfileView(
            viewModel: EditProfileViewModel(
                userModel: userModel,
                interactor: ProfileInteractor.mock,
                router: ProfileRouterMock(),
                analytics: ProfileAnalyticsMock()),
            avatar: nil,
            profileDidEdit: {_ in}
        )
    }
}
#endif
