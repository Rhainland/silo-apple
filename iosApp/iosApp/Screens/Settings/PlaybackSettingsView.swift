#if !os(tvOS)
import SwiftUI

/// Playback preferences sub-screen — a native grouped list in the
/// style of the iOS Settings app: plain rows, navigation-link pickers,
/// and footers for the fine print.
struct PlaybackSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showUseProfileSettingsConfirmation = false

    var body: some View {
        List {
            if viewModel.hasHeldPlaybackChanges {
                HeldSettingChangesSection(
                    retry: { await viewModel.retryHeldPlaybackChanges() },
                    discard: { await viewModel.discardHeldPlaybackChanges() },
                    message: viewModel.heldPlaybackChangesMessage
                )
            }
            if viewModel.playbackChangeWasRejected {
                rejectedChangeSection
            }
            streamingSection
            behaviorSection
            SeekIntervalSettingsSections()
            resetSection
        }
        .settingsListChrome()
        .navigationTitle("Playback")
        .siloNavigationTitleDisplayMode(.inline)
        .siloToolbarColorSchemeDark()
        .alert(
            SettingsViewModel.useProfileSettingsTitle,
            isPresented: $showUseProfileSettingsConfirmation
        ) {
            Button("Use Profile Settings", role: .destructive) {
                Task { await viewModel.resetPlaybackDeviceSettings() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(viewModel.useProfileSettingsMessage)
        }
    }

    // MARK: - Streaming

    private var streamingSection: some View {
        Section {
            Picker("Quality", selection: selection(.quality)) {
                useProfileSettingOption
                // A pair no preset covers — set through the API, or written by
                // a client whose ladder has a rung this table does not — gets
                // its own disabled entry describing what is actually stored,
                // rather than the picker showing a preset the user never chose.
                if !viewModel.usesProfileSetting(.quality), viewModel.preferredQualityPresetId == nil {
                    Text(viewModel.preferredQualityLabel)
                        .tag(SettingsViewModel.customQualityTag)
                }
                ForEach(SiloQualityPresets.all) { preset in
                    Text(preset.label).tag(preset.id)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            Picker("Audio Language", selection: selection(.audioLanguage)) {
                useProfileSettingOption
                if viewModel.hasStoredNoAudioLanguagePreference {
                    Text(
                        SettingPresentationMetadata.definitions[.playbackAudioLanguage]?.unsetLabel
                            ?? "No preference"
                    ).tag("")
                }
                ForEach(viewModel.audioLanguageOptions) { option in
                    Text(option.label).tag(option.code)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            Toggle("Dolby Vision", isOn: $viewModel.dolbyVisionEnabled)
                .foregroundStyle(Color.siloOnSurface)
                .tint(.siloSwitchOn)

            Toggle("Seek Cache", isOn: $viewModel.seekCacheEnabled)
                .foregroundStyle(Color.siloOnSurface)
                .tint(.siloSwitchOn)

            Picker("Buffer Ahead", selection: $viewModel.bufferAhead) {
                ForEach(BufferAheadMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            Toggle("Lossless Multichannel Audio", isOn: $viewModel.losslessAudioEnabled)
                .foregroundStyle(Color.siloOnSurface)
                .tint(.siloSwitchOn)

            Toggle("TrueHD Atmos", isOn: $viewModel.trueHDAtmosEnabled)
                .foregroundStyle(Color.siloOnSurface)
                .tint(.siloSwitchOn)

            Picker("Deinterlacing", selection: $viewModel.deinterlaceMode) {
                ForEach(DeinterlacePreference.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            Picker("Deinterlacing Field Rate", selection: $viewModel.deinterlaceFieldRate) {
                ForEach(DeinterlaceFieldRatePreference.allCases, id: \.self) { rate in
                    Text(rate.label).tag(rate)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            // iOS only: the engine's background policy is driven by the app
            // lifecycle notifications, which macOS does not post — a toggle
            // there would control nothing.
            #if os(iOS)
            Toggle("Background Playback", isOn: $viewModel.backgroundPlaybackEnabled)
                .foregroundStyle(Color.siloOnSurface)
                .tint(.siloSwitchOn)
            #endif
        } header: {
            Text("Streaming")
                .foregroundStyle(Color.siloSecondaryText)
        } footer: {
            Text(streamingFooterText)
                .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }

    private var streamingFooterText: String {
        // Leads with what the chosen quality actually means, since the preset
        // labels ("1080p High") name a tier without stating its bitrate.
        var text = "\(viewModel.preferredQualityLabel)."
        if let preset = SiloQualityPresets.preset(id: viewModel.preferredQualityPresetId) {
            text = preset.description
        }
        text += " If surround plays as stereo, turn off Lossless Multichannel Audio."
        text += " TrueHD Atmos adds height channels but plays those tracks as compressed audio."
        return text
    }

    // MARK: - Behavior

    private var behaviorSection: some View {
        Section {
            // On / Off pickers rather than switches: a switch has no third
            // position for going back to the profile's choice.
            Picker("Auto-Play Next Episode", selection: selection(.autoPlayNext)) {
                useProfileSettingOption
                onOffOptions
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            Picker("Show Next Up", selection: selection(.nextUpPrompt)) {
                useProfileSettingOption
                ForEach(nextUpPromptOptions, id: \.0) { seconds, label in
                    Text(label).tag(String(seconds))
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            // Three-way (labels fixed by the contract).
            Picker("Skip Intros", selection: selection(.introSkipMode)) {
                useProfileSettingOption
                ForEach(IntroSkipMode.allCases) { mode in
                    Text(mode.label).tag(mode.wireValue)
                }
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()

            Picker("Skip Credits", selection: selection(.autoSkipCredits)) {
                useProfileSettingOption
                onOffOptions
            }
            .foregroundStyle(Color.siloOnSurface)
            .settingsPickerStyle()
        } header: {
            Text("Episodes")
                .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }

    // MARK: - Refused change

    private var rejectedChangeSection: some View {
        Section {
            Button("OK") {
                Task { await viewModel.acknowledgeRejectedPlaybackChange() }
            }
        } header: {
            Text("Not Saved")
                .foregroundStyle(Color.siloSecondaryText)
        } footer: {
            Text(SettingsViewModel.rejectedPlaybackChangeMessage)
                .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }

    // MARK: - Use Profile Settings

    private var resetSection: some View {
        Section {
            Button("Use Profile Settings", role: .destructive) {
                showUseProfileSettingsConfirmation = true
            }
        } footer: {
            Text("Removes the settings changed on this device, so it uses your profile's settings again.")
                .foregroundStyle(Color.siloSecondaryText)
        }
        .listRowBackground(Color.siloGroupedCell)
    }

    // MARK: - Options

    private func selection(_ setting: ProfileBackedPlaybackSetting) -> Binding<String> {
        Binding(
            get: { viewModel.playbackSelectionTag(setting) },
            set: { viewModel.selectPlayback($0, for: setting) }
        )
    }

    private var useProfileSettingOption: some View {
        Text(SettingsViewModel.useProfileSettingLabel)
            .tag(SettingsViewModel.useProfileSettingTag)
    }

    @ViewBuilder
    private var onOffOptions: some View {
        Text("On").tag(SettingsViewModel.onTag)
        Text("Off").tag(SettingsViewModel.offTag)
    }

    private var nextUpPromptOptions: [(Int, String)] {
        [
            (0, "At end"),
            (10, "10 seconds before end"),
            (30, "30 seconds before end"),
            (60, "1 minute before end"),
            (120, "2 minutes before end"),
        ]
    }
}
#endif
