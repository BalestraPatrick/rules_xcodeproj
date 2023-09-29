import OrderedCollections
import PBXProj
import XCScheme

extension Generator {
    struct CreateScheme {
        private let createAnalyzeAction: CreateAnalyzeAction
        private let createArchiveAction: CreateArchiveAction
        private let createBuildAction: CreateBuildAction
        private let createLaunchAction: CreateLaunchAction
        private let createProfileAction: CreateProfileAction
        private let createSchemeXML: XCScheme.CreateScheme
        private let createTestAction: CreateTestAction

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            createAnalyzeAction: CreateAnalyzeAction,
            createArchiveAction: CreateArchiveAction,
            createBuildAction: CreateBuildAction,
            createLaunchAction: CreateLaunchAction,
            createProfileAction: CreateProfileAction,
            createSchemeXML: XCScheme.CreateScheme,
            createTestAction: CreateTestAction,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.createAnalyzeAction = createAnalyzeAction
            self.createArchiveAction = createArchiveAction
            self.createBuildAction = createBuildAction
            self.createLaunchAction = createLaunchAction
            self.createProfileAction = createProfileAction
            self.createSchemeXML = createSchemeXML
            self.createTestAction = createTestAction

            self.callable = callable
        }

        /// Creates the XML for an automatically generated `.xcscheme` file.
        func callAsFunction(
            defaultXcodeConfiguration: String,
            extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
            schemeInfo: SchemeInfo
        ) throws -> (name: String, scheme: String) {
            return try callable(
                /*defaultXcodeConfiguration:*/ defaultXcodeConfiguration,
                /*extensionPointIdentifiers:*/ extensionPointIdentifiers,
                /*schemeInfo:*/ schemeInfo,
                /*createAnalyzeAction:*/ createAnalyzeAction,
                /*createArchiveAction:*/ createArchiveAction,
                /*createBuildAction:*/ createBuildAction,
                /*createLaunchAction:*/ createLaunchAction,
                /*createProfileAction:*/ createProfileAction,
                /*createSchemeXML:*/ createSchemeXML,
                /*createTestAction:*/ createTestAction
            )
        }
    }
}

// MARK: - CreateScheme.Callable

extension Generator.CreateScheme {
    typealias Callable = (
        _ defaultXcodeConfiguration: String,
        _ extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        _ schemeInfo: SchemeInfo,
        _ createAnalyzeAction: CreateAnalyzeAction,
        _ createArchiveAction: CreateArchiveAction,
        _ createBuildAction: CreateBuildAction,
        _ createLaunchAction: CreateLaunchAction,
        _ createProfileAction: CreateProfileAction,
        _ createSchemeXML: XCScheme.CreateScheme,
        _ createTestAction: CreateTestAction
    ) throws -> (name: String, scheme: String)

    static func defaultCallable(
        defaultXcodeConfiguration: String,
        extensionPointIdentifiers: [TargetID: ExtensionPointIdentifier],
        schemeInfo: SchemeInfo,
        createAnalyzeAction: CreateAnalyzeAction,
        createArchiveAction: CreateArchiveAction,
        createBuildAction: CreateBuildAction,
        createLaunchAction: CreateLaunchAction,
        createProfileAction: CreateProfileAction,
        createSchemeXML:  XCScheme.CreateScheme,
        createTestAction: CreateTestAction
    ) throws -> (name: String, scheme: String) {
        var buildActionEntries:
            OrderedDictionary<String, BuildActionEntry> = [:]
        func adjustBuildActionEntry(
            for reference: BuildableReference,
            include buildFor: BuildActionEntry.BuildFor
        ) {
            buildActionEntries[
                reference.blueprintIdentifier,
                default: .init(
                    buildableReference: reference,
                    buildFor: []
                )
            ].buildFor.formUnion(buildFor)
        }

        var buildPostActions: [ExecutionAction] = []
        var buildPreActions: [ExecutionAction] = []
        var launchPostActions: [ExecutionAction] = []
        var launchPreActions: [ExecutionAction] = []
        var profilePostActions: [ExecutionAction] = []
        var profilePreActions: [ExecutionAction] = []
        var testPostActions: [ExecutionAction] = []
        var testPreActions: [ExecutionAction] = []

        // FIXME: Order these based on `.order`
        func handleExecutionAction(
            _ executionAction: SchemeInfo.ExecutionAction
        ) {
            let schemeExecutionAction = ExecutionAction(
                title: executionAction.title,
                escapedScriptText:
                    executionAction.scriptText.schemeXmlEscaped,
                expandVariablesBasedOn:
                    executionAction.target.buildableReference
            )

            switch (executionAction.action, executionAction.isPreAction) {
            case (.build, true):
                buildPreActions.append(schemeExecutionAction)
            case (.build, false):
                buildPostActions.append(schemeExecutionAction)
            case (.run, true):
                launchPreActions.append(schemeExecutionAction)
            case (.run, false):
                launchPostActions.append(schemeExecutionAction)
            case (.test, true):
                testPreActions.append(schemeExecutionAction)
            case (.test, false):
                testPostActions.append(schemeExecutionAction)
            case (.profile, true):
                profilePreActions.append(schemeExecutionAction)
            case (.profile, false):
                profilePostActions.append(schemeExecutionAction)
            }
        }

        // MARK: Run

        let launchBuildConfiguration = schemeInfo.run.xcodeConfiguration ??
            defaultXcodeConfiguration

        let launchRunnable: Runnable?
        let wasCreatedForAppExtension: Bool
        if let launchTarget = schemeInfo.run.launchTarget {
            let buildableReference =
                launchTarget.primary.buildableReference

            adjustBuildActionEntry(
                for: buildableReference,
                include: [.running, .analyzing]
            )

            if let extensionHost = launchTarget.extensionHost {
                let hostBuildableReference = extensionHost.buildableReference

                adjustBuildActionEntry(
                    for: hostBuildableReference,
                    include: [.running, .analyzing]
                )

                let extensionPointIdentifier = try extensionPointIdentifiers
                    .value(
                        for: launchTarget.primary.key.sortedIds.first!,
                        context: "Extension Target ID"
                    )

                launchRunnable = .hosted(
                    buildableReference: buildableReference,
                    hostBuildableReference: hostBuildableReference,
                    debuggingMode: extensionPointIdentifier.debuggingMode,
                    remoteBundleIdentifier:
                        extensionPointIdentifier.remoteBundleIdentifier
                )
                wasCreatedForAppExtension = true
            } else {
                launchRunnable = .plain(buildableReference: buildableReference)
                wasCreatedForAppExtension = false
            }

            launchPreActions.append(
                .updateLldbInitAndCopyDSYMs(for: buildableReference)
            )
        } else {
            launchRunnable = nil
            wasCreatedForAppExtension = false
        }

        for buildOnlyTarget in schemeInfo.run.buildTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.buildableReference,
                include: [.running, .analyzing]
            )
        }

        // MARK: Profile

        let profileRunnable: Runnable?
        if let launchTarget = schemeInfo.profile.launchTarget {
            let buildableReference =
                launchTarget.primary.buildableReference

            adjustBuildActionEntry(for: buildableReference, include: .profiling)

            if let extensionHost = launchTarget.extensionHost {
                let hostBuildableReference = extensionHost.buildableReference

                adjustBuildActionEntry(
                    for: hostBuildableReference,
                    include: .profiling
                )

                let extensionPointIdentifier = try extensionPointIdentifiers
                    .value(
                        for: launchTarget.primary.key.sortedIds.first!,
                        context: "Extension Target ID"
                    )

                profileRunnable = .hosted(
                    buildableReference: buildableReference,
                    hostBuildableReference: hostBuildableReference,
                    debuggingMode: extensionPointIdentifier.debuggingMode,
                    remoteBundleIdentifier:
                        extensionPointIdentifier.remoteBundleIdentifier
                )
            } else {
                profileRunnable =
                    .plain(buildableReference: buildableReference)
            }

            profilePreActions.append(
                .updateLldbInitAndCopyDSYMs(for: buildableReference)
            )
        } else {
            profileRunnable = nil
        }

        for buildOnlyTarget in schemeInfo.profile.buildTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.buildableReference,
                include: .profiling
            )
        }

        // MARK: Test

        for buildOnlyTarget in schemeInfo.test.buildTargets {
            adjustBuildActionEntry(
                for: buildOnlyTarget.buildableReference,
                include: .testing
            )
        }

        // We process `testTargets` after `buildTargets` to ensure that
        // test bundle icons are only used for a scheme if there are no launch
        // or library targets declared
        var testables: [Testable] = []
        for testTarget in schemeInfo.test.testTargets {
            let buildableTarget = testTarget.target
            let buildableReference = buildableTarget.buildableReference

            adjustBuildActionEntry(for: buildableReference, include: .testing)

            testables.append(
                .init(
                    buildableReference: buildableReference,
                    skipped: !testTarget.enabled
                )
            )
        }

        // If we have a testable, use the first one to update `.lldbinit`
        if let buildableReference = testables.first?.buildableReference {
            testPreActions.insert(
                .updateLldbInitAndCopyDSYMs(for: buildableReference),
                at: 0
            )
        }

        // MARK: Execution actions

        for executionAction in schemeInfo.executionActions {
            handleExecutionAction(executionAction)
        }

        // MARK: Xcode Previews additional targets

        for reference in schemeInfo.run.transitivePreviewReferences {
            adjustBuildActionEntry(for: reference, include: .running)
        }

        // MARK: Build

        let buildActionEntryValues: [BuildActionEntry]

        let unsortedBuildActionEntries = buildActionEntries.values.elements
        let restStartIndex = buildActionEntries.values.elements.startIndex.advanced(by: 1)
        let restEndIndex = buildActionEntries.values.elements.endIndex
        if restStartIndex < restStartIndex {
            // Keep the first element as first, then sort the test by name.
            // This ensure that Run action launch targets, a library target,
            // or finally a test target, is listed first. This influences the
            // icon shown for the scheme in Xcode.
            buildActionEntryValues = [unsortedBuildActionEntries.first!] +
                (unsortedBuildActionEntries[restStartIndex ..< restEndIndex])
                .sorted { lhs, rhs in
                    return lhs.buildableReference.blueprintName
                        .localizedStandardCompare(
                            rhs.buildableReference.blueprintName
                        ) == .orderedAscending
            }
        } else {
            buildActionEntryValues = buildActionEntries.values.elements
        }

        if let firstReference =
            buildActionEntryValues.first?.buildableReference
        {
            // Use the first build entry for our Bazel support build pre-actions
            buildPreActions.insert(
                contentsOf: [
                    .initializeBazelBuildOutputGroupsFile(
                        with: firstReference
                    ),
                    .prepareBazelDependencies(with: firstReference),
                ],
                at: 0
            )
        }

        // MARK: Scheme

        let scheme = createSchemeXML(
            buildAction: createBuildAction(
                entries: buildActionEntryValues,
                postActions: buildPostActions,
                preActions: buildPreActions
            ),
            testAction: createTestAction(
                buildConfiguration: schemeInfo.test.xcodeConfiguration ??
                    defaultXcodeConfiguration,
                commandLineArguments: schemeInfo.test.commandLineArguments,
                enableAddressSanitizer: schemeInfo.test.enableAddressSanitizer,
                enableThreadSanitizer: schemeInfo.test.enableThreadSanitizer,
                enableUBSanitizer: schemeInfo.test.enableUBSanitizer,
                environmentVariables: schemeInfo.test.environmentVariables,
                expandVariablesBasedOn: schemeInfo.test.useRunArgsAndEnv ?
                    nil : testables.first?.buildableReference,
                postActions: testPostActions,
                preActions: testPreActions,
                testables: testables,
                useLaunchSchemeArgsEnv: schemeInfo.test.useRunArgsAndEnv
            ),
            launchAction: createLaunchAction(
                buildConfiguration: launchBuildConfiguration,
                commandLineArguments: schemeInfo.run.commandLineArguments,
                customWorkingDirectory: schemeInfo.run.customWorkingDirectory,
                enableAddressSanitizer: schemeInfo.run.enableAddressSanitizer,
                enableThreadSanitizer: schemeInfo.run.enableThreadSanitizer,
                enableUBSanitizer: schemeInfo.run.enableUBSanitizer,
                environmentVariables: schemeInfo.run.environmentVariables,
                postActions: launchPostActions,
                preActions: launchPreActions,
                runnable: launchRunnable
            ),
            profileAction: createProfileAction(
                buildConfiguration: schemeInfo.profile.xcodeConfiguration ??
                    defaultXcodeConfiguration,
                commandLineArguments: schemeInfo.run.commandLineArguments,
                customWorkingDirectory: schemeInfo.run.customWorkingDirectory,
                environmentVariables: schemeInfo.run.environmentVariables,
                postActions: profilePostActions,
                preActions: profilePreActions,
                useLaunchSchemeArgsEnv: true,
                runnable: profileRunnable
            ),
            analyzeAction: createAnalyzeAction(
                buildConfiguration: launchBuildConfiguration
            ),
            archiveAction: createArchiveAction(
                buildConfiguration: launchBuildConfiguration
            ),
            wasCreatedForAppExtension: wasCreatedForAppExtension
        )

        return (schemeInfo.name, scheme)
    }
}
