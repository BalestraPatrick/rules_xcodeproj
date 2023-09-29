import Foundation
import GeneratorCommon
import PBXProj
import XCScheme

extension Generator {
    struct CreateCustomSchemeInfos {
        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.callable = callable
        }

        /// Creates and writes automatically generated `.xcscheme`s to disk.
        func callAsFunction(
            argsEnvFile: URL,
            commandLineArguments: [TargetID: [CommandLineArgument]],
            customSchemeArguments: CustomSchemesArguments,
            environmentVariables: [TargetID: [EnvironmentVariable]],
            executionActionsFile: URL,
            extensionHostIDs: [TargetID: [TargetID]],
            targetsByID: [TargetID: Target],
            transitivePreviewReferences: [TargetID: [BuildableReference]]
        ) async throws -> [SchemeInfo] {
            try await callable(
                /*argsEnvFile:*/ argsEnvFile,
                /*commandLineArguments:*/ commandLineArguments,
                /*customSchemeArguments:*/ customSchemeArguments,
                /*environmentVariables:*/ environmentVariables,
                /*executionActionsFile:*/ executionActionsFile,
                /*extensionHostIDs:*/ extensionHostIDs,
                /*targetsByID:*/ targetsByID,
                /*transitivePreviewReferences:*/ transitivePreviewReferences
            )
        }
    }
}

// MARK: - CreateCustomSchemeInfos.Callable

extension Generator.CreateCustomSchemeInfos {
    typealias Callable = (
        _ argsEnvFile: URL,
        _ commandLineArguments: [TargetID: [CommandLineArgument]],
        _ customSchemeArguments: CustomSchemesArguments,
        _ environmentVariables: [TargetID: [EnvironmentVariable]],
        _ executionActionsFile: URL,
        _ extensionHostIDs: [TargetID: [TargetID]],
        _ targetsByID: [TargetID: Target],
        _ transitivePreviewReferences: [TargetID: [BuildableReference]]
    ) async throws -> [SchemeInfo]

    static func defaultCallable(
        argsEnvFile: URL,
        commandLineArguments: [TargetID: [CommandLineArgument]],
        customSchemeArguments: CustomSchemesArguments,
        environmentVariables: [TargetID: [EnvironmentVariable]],
        executionActionsFile: URL,
        extensionHostIDs: [TargetID: [TargetID]],
        targetsByID: [TargetID: Target],
        transitivePreviewReferences: [TargetID: [BuildableReference]]
    ) async throws -> [SchemeInfo] {
        return try await customSchemeArguments.calculateSchemeInfos(
            argsEnvFile: argsEnvFile,
            commandLineArguments: commandLineArguments,
            environmentVariables: environmentVariables,
            executionActionsFile: executionActionsFile,
            extensionHostIDs: extensionHostIDs,
            targetsByID: targetsByID,
            transitivePreviewReferences: transitivePreviewReferences
        )
    }
}

extension CustomSchemesArguments {
    func calculateSchemeInfos(
        argsEnvFile: URL,
        commandLineArguments: [TargetID: [CommandLineArgument]],
        environmentVariables: [TargetID: [EnvironmentVariable]],
        executionActionsFile: URL,
        extensionHostIDs: [TargetID: [TargetID]],
        targetsByID: [TargetID: Target],
        transitivePreviewReferences: [TargetID: [BuildableReference]]
    ) async throws -> [SchemeInfo] {
        let executionActions = try await executionActionsArguments
            .calculateExecutionActions(
                from: executionActionsFile,
                targetsByID: targetsByID
            )

        let rawArgsAndEnv = try await argsEnvFile.allLines.collect()

        let testCommandLineArgumentCountsSum =
            testCommandLineArgumentCounts.reduce(0, +)
        let testEnvironmentVariableCountsSum =
            testEnvironmentVariableCounts.reduce(0, +)
        let runCommandLineArgumentCountsSum =
            runCommandLineArgumentCounts.reduce(0, +)
        let runEnvironmentVariableCountsSum =
            runEnvironmentVariableCounts.reduce(0, +)
        let profileCommandLineArgumentCountsSum =
            profileCommandLineArgumentCounts.reduce(0, +)
        let profileEnvironmentVariableCountsSum =
            profileEnvironmentVariableCounts.reduce(0, +)

        let expectedSum = testCommandLineArgumentCountsSum +
            testEnvironmentVariableCountsSum * 2 +
            runCommandLineArgumentCountsSum +
            runEnvironmentVariableCountsSum * 2 +
            profileCommandLineArgumentCountsSum +
            profileEnvironmentVariableCountsSum * 2
        guard expectedSum == rawArgsAndEnv.count else {
            throw PreconditionError(message: """
Number of lines in "\(argsEnvFile.path)" (\(rawArgsAndEnv.count)) does not \
match what is specified with <test-command-line-argument-counts> \
(\(testCommandLineArgumentCountsSum)), <test-environment-variables-counts> \
(\(testEnvironmentVariableCountsSum)), <run-command-line-argument-counts> \
(\(runCommandLineArgumentCountsSum)), <run-environment-variables-counts> \
(\(runEnvironmentVariableCountsSum)), <profile-command-line-argument-counts> \
(\(profileCommandLineArgumentCountsSum)), and \
<profile-environment-variables-counts> \
(\(profileEnvironmentVariableCountsSum)). It should equal \(expectedSum).
""")
        }

        var rawArgsAndEnvStartIndex = rawArgsAndEnv.startIndex

        var testBuildTargetsStartIndex = testBuildTargets.startIndex
        var testCommandLineArgumentEnabledStatesStartIndex =
            testCommandLineArgumentEnabledStates.startIndex
        var testEnvironmentVariableEnabledStatesStartIndex =
            testEnvironmentVariableEnabledStates.startIndex
        var testTargetsStartIndex = testTargets.startIndex

        var runBuildTargetsStartIndex = runBuildTargets.startIndex
        var runCommandLineArgumentEnabledStatesStartIndex =
            runCommandLineArgumentEnabledStates.startIndex
        var runEnvironmentVariableEnabledStatesStartIndex =
            runEnvironmentVariableEnabledStates.startIndex

        var profileBuildTargetsStartIndex =
            profileBuildTargets.startIndex
        var profileCommandLineArgumentEnabledStatesStartIndex =
            profileCommandLineArgumentEnabledStates.startIndex
        var profileEnvironmentVariableEnabledStatesStartIndex =
            profileEnvironmentVariableEnabledStates.startIndex

        var schemeInfos: [SchemeInfo] = []
        for schemeIndex in customSchemes.indices {
            let name = customSchemes[schemeIndex]
            let executionActions = executionActions[name, default: []]

            var allTargetIDs: Set<TargetID> = []

            // MARK: Test

            let testBuildTargets = try testBuildTargets
                .targetsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: testBuildTargetCounts,
                    startIndex: &testBuildTargetsStartIndex,
                    targetsByID: targetsByID,
                    context: "Test build only target"
                )
            var testCommandLineArguments = rawArgsAndEnv
                .commandLineArgumentsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: testCommandLineArgumentCounts,
                    enabledStates: testCommandLineArgumentEnabledStates,
                    startIndex: &rawArgsAndEnvStartIndex,
                    enabledStatesStartIndex:
                        &testCommandLineArgumentEnabledStatesStartIndex
                )
            var testEnvironmentVariables = rawArgsAndEnv
                .environmentVariablesSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: testEnvironmentVariableCounts,
                    enabledStates: testEnvironmentVariableEnabledStates,
                    startIndex: &rawArgsAndEnvStartIndex,
                    enabledStatesStartIndex:
                        &testEnvironmentVariableEnabledStatesStartIndex
                )
            let testTargets = try testTargets.testTargetsSlicedBy(
                schemeIndex: schemeIndex,
                counts: testTargetCounts,
                enabledStates: testTargetEnabledStates,
                startIndex: &testTargetsStartIndex,
                targetsByID: targetsByID,
                context: "Test target"
            )
            let testUseRunArgsAndEnvEnabledStates =
                testUseRunArgsAndEnvEnabledStates[schemeIndex]

            if let id = testTargets.first?.target.key.sortedIds.first! {
                // If the custom scheme doesn't define any command-line
                // arguments, and every test target define the same args, then
                // use them
                if testCommandLineArguments.isEmpty,
                   let aCommandLineArguments = commandLineArguments[id]
                {
                    var allCommandLineArgumentsTheSame = true
                    for testTarget in testTargets {
                        let id = testTarget.target.key.sortedIds.first!
                        guard aCommandLineArguments == commandLineArguments[id]
                        else {
                            allCommandLineArgumentsTheSame = false
                            break
                        }
                    }

                    if allCommandLineArgumentsTheSame {
                        testCommandLineArguments = aCommandLineArguments
                    }
                }

                // If the custom scheme doesn't define any environment
                // variables, and every test target define the same env, then
                // use them
                if testEnvironmentVariables.isEmpty,
                   let aEnvironmentVariables = environmentVariables[id]
                {
                    var allEnvironmentVariablesTheSame = true
                    for testTarget in testTargets {
                        let id = testTarget.target.key.sortedIds.first!
                        guard aEnvironmentVariables == environmentVariables[id]
                        else {
                            allEnvironmentVariablesTheSame = false
                            break
                        }
                    }

                    if allEnvironmentVariablesTheSame {
                        testEnvironmentVariables = aEnvironmentVariables
                    }
                }
            }

            if testEnvironmentVariablesIncludeDefaults[schemeIndex] {
                testEnvironmentVariables.insert(
                    contentsOf: Array.defaultEnvironmentVariables,
                    at: 0
                )
            }

            allTargetIDs.formUnion(testBuildTargets.map(\.key.sortedIds.first!))
            allTargetIDs
                .formUnion(testTargets.map(\.target.key.sortedIds.first!))

            // MARK: Run

            let runBuildTargets = try runBuildTargets
                .targetsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: runBuildTargetCounts,
                    startIndex: &runBuildTargetsStartIndex,
                    targetsByID: targetsByID,
                    context: "Run build only target"
                )
            var runCommandLineArguments = rawArgsAndEnv
                .commandLineArgumentsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: runCommandLineArgumentCounts,
                    enabledStates: runCommandLineArgumentEnabledStates,
                    startIndex: &rawArgsAndEnvStartIndex,
                    enabledStatesStartIndex:
                        &runCommandLineArgumentEnabledStatesStartIndex
                )
            var runEnvironmentVariables = rawArgsAndEnv
                .environmentVariablesSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: runEnvironmentVariableCounts,
                    enabledStates: runEnvironmentVariableEnabledStates,
                    startIndex: &rawArgsAndEnvStartIndex,
                    enabledStatesStartIndex:
                        &runEnvironmentVariableEnabledStatesStartIndex
                )

            let runLaunchTarget: SchemeInfo.LaunchTarget?
            if let runLaunchTargetID = runLaunchTargets[schemeIndex] {
                allTargetIDs.insert(runLaunchTargetID)

                runLaunchTarget = try SchemeInfo.LaunchTarget(
                    id: runLaunchTargetID,
                    extensionHost: runLaunchExtensionHosts[
                        schemeIndex
                    ],
                    extensionHostIDs: extensionHostIDs,
                    targetsByID: targetsByID,
                    context: #"Custom scheme "\#(name)"'s run launch target"#
                )

                // Only set from-rule args and env if the custom scheme doesn't
                // declare any
                // TODO: Distinguish between `None` and `[]` in `xcshemes`?
                if runCommandLineArguments.isEmpty,
                   let commandLineArguments =
                    commandLineArguments[runLaunchTargetID]
                {
                    runCommandLineArguments = commandLineArguments
                }
                if runEnvironmentVariables.isEmpty,
                   let environmentVariables =
                    environmentVariables[runLaunchTargetID]
                {
                    runEnvironmentVariables = environmentVariables
                }
            } else {
                runLaunchTarget = nil
            }

            if runEnvironmentVariablesIncludeDefaults[schemeIndex] {
                runEnvironmentVariables.insert(
                    contentsOf: Array.defaultEnvironmentVariables,
                    at: 0
                )
            }

            allTargetIDs.formUnion(runBuildTargets.map(\.key.sortedIds.first!))

            // MARK: Profile

            let profileBuildTargets = try profileBuildTargets
                .targetsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: profileBuildTargetCounts,
                    startIndex: &profileBuildTargetsStartIndex,
                    targetsByID: targetsByID,
                    context: "Profile build only target"
                )
            var profileCommandLineArguments = rawArgsAndEnv
                .commandLineArgumentsSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: profileCommandLineArgumentCounts,
                    enabledStates: profileCommandLineArgumentEnabledStates,
                    startIndex: &rawArgsAndEnvStartIndex,
                    enabledStatesStartIndex:
                        &profileCommandLineArgumentEnabledStatesStartIndex
                )
            var profileEnvironmentVariables = rawArgsAndEnv
                .environmentVariablesSlicedBy(
                    schemeIndex: schemeIndex,
                    counts: profileEnvironmentVariableCounts,
                    enabledStates: profileEnvironmentVariableEnabledStates,
                    startIndex: &rawArgsAndEnvStartIndex,
                    enabledStatesStartIndex:
                        &profileEnvironmentVariableEnabledStatesStartIndex
                )
            let profileUseRunArgsAndEnvEnabledStates =
                profileUseRunArgsAndEnvEnabledStates[schemeIndex]

            let profileLaunchTarget: SchemeInfo.LaunchTarget?
            if let profileLaunchTargetID = profileLaunchTargets[schemeIndex] {
                allTargetIDs.insert(profileLaunchTargetID)

                profileLaunchTarget = try SchemeInfo.LaunchTarget(
                    id: profileLaunchTargetID,
                    extensionHost: profileLaunchExtensionHosts[
                        schemeIndex
                    ],
                    extensionHostIDs: extensionHostIDs,
                    targetsByID: targetsByID,
                    context:
                        #"Custom scheme "\#(name)"'s profile launch target"#
                )

                // Only set from-rule args and env if the custom scheme doesn't
                // declare any
                // TODO: Distinguish between `None` and `[]` in `xcshemes`?
                if profileCommandLineArguments.isEmpty,
                   let commandLineArguments =
                    commandLineArguments[profileLaunchTargetID]
                {
                    profileCommandLineArguments = commandLineArguments
                }
                if profileEnvironmentVariables.isEmpty,
                   let environmentVariables =
                    environmentVariables[profileLaunchTargetID]
                {
                    profileEnvironmentVariables = environmentVariables
                }
            } else {
                profileLaunchTarget = nil
            }

            if profileEnvironmentVariablesIncludeDefaults[schemeIndex] {
                profileEnvironmentVariables.insert(
                    contentsOf: Array.defaultEnvironmentVariables,
                    at: 0
                )
            }

            allTargetIDs
                .formUnion(profileBuildTargets.map(\.key.sortedIds.first!))

            // MARK: Scheme

            let transitivePreviewReferences = Array(Set(
                allTargetIDs.flatMap { id in
                    return transitivePreviewReferences[id, default: []]
                }
            ))

            schemeInfos.append(
                SchemeInfo(
                    name: name,
                    test: SchemeInfo.Test(
                        buildTargets: testBuildTargets,
                        commandLineArguments: testCommandLineArguments,
                        enableAddressSanitizer:
                            testAddressSanitizerEnabledStates[schemeIndex],
                        enableThreadSanitizer:
                            testThreadSanitizerEnabledStates[schemeIndex],
                        enableUBSanitizer:
                            testUBSanitizerEnabledStates[schemeIndex],
                        environmentVariables: testEnvironmentVariables,
                        testTargets: testTargets,
                        useRunArgsAndEnv: testUseRunArgsAndEnvEnabledStates,
                        xcodeConfiguration: testXcodeConfigurations[schemeIndex]
                    ),
                    run: SchemeInfo.Run(
                        buildTargets: runBuildTargets,
                        commandLineArguments: runCommandLineArguments,
                        customWorkingDirectory:
                            runWorkingDirectories[schemeIndex],
                        enableAddressSanitizer:
                            runAddressSanitizerEnabledStates[schemeIndex],
                        enableThreadSanitizer:
                            runThreadSanitizerEnabledStates[schemeIndex],
                        enableUBSanitizer:
                            runUBSanitizerEnabledStates[schemeIndex],
                        environmentVariables: runEnvironmentVariables,
                        launchTarget: runLaunchTarget,
                        transitivePreviewReferences:
                            transitivePreviewReferences,
                        xcodeConfiguration: runXcodeConfigurations[schemeIndex]
                    ),
                    profile: SchemeInfo.Profile(
                        buildTargets: profileBuildTargets,
                        commandLineArguments: profileCommandLineArguments,
                        customWorkingDirectory:
                            profileWorkingDirectories[schemeIndex],
                        environmentVariables: profileEnvironmentVariables,
                        launchTarget: profileLaunchTarget,
                        useRunArgsAndEnv: profileUseRunArgsAndEnvEnabledStates,
                        xcodeConfiguration:
                            profileXcodeConfigurations[schemeIndex]
                    ),
                    executionActions: executionActions
                )
            )
        }

        return schemeInfos
    }
}

private extension SchemeInfo.LaunchTarget {
    init(
        id: TargetID,
        extensionHost: TargetID?,
        extensionHostIDs: [TargetID: [TargetID]],
        targetsByID: [TargetID: Target],
        context: @autoclosure () -> String
    ) throws {
        let target = try targetsByID.value(
            for: id,
            context: context()
        )

        guard !target.productType.needsExtensionHost ||
                extensionHost != nil
        else {
            throw UsageError(message: """
\(context()) (\(id)) is an app extension and requires `extension_host` to be \
set
""")
        }

        let extensionHost = try extensionHost.flatMap { extensionHostID in
            guard extensionHostIDs[id, default: []]
                .contains(where: { $0 == extensionHostID })
            else {
                throw UsageError(message: """
\(context()) `extension_host` (\(extensionHostID)) does not host the extension \
(\(id))
""")
            }
            return try targetsByID.value(
                for: extensionHostID,
                context: "\(context()) extension host"
            )
        }

        self.init(
            primary: target,
            extensionHost: extensionHost
        )
    }
}

private extension Array {
    func slicedBy<CountsCollection>(
        schemeIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index
    ) -> Self where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return self
        }

        let endIndex = startIndex.advanced(by: counts[schemeIndex])
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return Array(self[range])
    }
}

private extension Array where Element == TargetID {
    func targetsSlicedBy<CountsCollection>(
        schemeIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index,
        targetsByID: [TargetID: Target],
        context: @autoclosure () -> String
    ) throws -> [Target] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let endIndex = startIndex.advanced(by: counts[schemeIndex])
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return try self[range].map { id in
            return try targetsByID.value(for: id, context: context())
        }
    }
}

private extension Array where Element == String {
    func commandLineArgumentsSlicedBy<
        CountsCollection,
        EnabledStatesCollection
    >(
        schemeIndex: Int,
        counts: CountsCollection,
        enabledStates: EnabledStatesCollection,
        startIndex: inout Index,
        enabledStatesStartIndex: inout Index
    ) -> [CommandLineArgument] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index,
        EnabledStatesCollection: RandomAccessCollection,
        EnabledStatesCollection.Element == Bool,
        EnabledStatesCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let count = counts[schemeIndex]
        guard count > 0 else {
            return []
        }

        let endIndex = startIndex.advanced(by: count)
        let range = startIndex ..< endIndex
        startIndex = endIndex

        let enabledStatesEndIndex = enabledStatesStartIndex.advanced(by: count)
        let enabledStatesRange =
            enabledStatesStartIndex ..< enabledStatesEndIndex
        enabledStatesStartIndex = enabledStatesEndIndex

        return zip(self[range], enabledStates[enabledStatesRange])
            .map { .init(value: $0.nullsToNewlines, enabled: $1) }
    }

    func environmentVariablesSlicedBy<
        CountsCollection,
        EnabledStatesCollection
    >(
        schemeIndex: Int,
        counts: CountsCollection,
        enabledStates: EnabledStatesCollection,
        startIndex: inout Index,
        enabledStatesStartIndex: inout Index
    ) -> [EnvironmentVariable] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index,
        EnabledStatesCollection: RandomAccessCollection,
        EnabledStatesCollection.Element == Bool,
        EnabledStatesCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let count = counts[schemeIndex]
        guard count > 0 else {
            return []
        }

        let enabledStatesEndIndex = enabledStatesStartIndex.advanced(by: count)
        let enabledStatesRange =
            enabledStatesStartIndex ..< enabledStatesEndIndex
        enabledStatesStartIndex = enabledStatesEndIndex

        let endIndex = startIndex.advanced(by: count * 2)
        defer {
            startIndex = endIndex
        }

        return zip(
            stride(from: startIndex, to: endIndex, by: 2),
            enabledStates[enabledStatesRange]
        ).lazy.map {
            return EnvironmentVariable(
                key: self[$0].nullsToNewlines,
                value: self[$0+1].nullsToNewlines,
                enabled: $1
            )
        }
    }
}

private extension Array where Element == TargetID {
    func testTargetsSlicedBy<CountsCollection, EnabledStatesCollection>(
        schemeIndex: Int,
        counts: CountsCollection,
        enabledStates: EnabledStatesCollection,
        startIndex: inout Index,
        targetsByID: [TargetID: Target],
        context: @autoclosure () -> String
    ) throws -> [SchemeInfo.TestTarget] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index,
        EnabledStatesCollection: RandomAccessCollection,
        EnabledStatesCollection.Element == Bool,
        EnabledStatesCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let count = counts[schemeIndex]
        guard count > 0 else {
            return []
        }

        let endIndex = startIndex.advanced(by: count)
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return try zip(self[range], enabledStates[range]).map { id, enabled in
            return .init(
                target: try targetsByID.value(for: id, context: context()),
                enabled: enabled
            )
        }
    }
}

private extension PBXProductType {
    var needsExtensionHost: Bool {
        switch self {
        case .appExtension,
                .intentsServiceExtension,
                .messagesExtension,
                .tvExtension,
                .extensionKitExtension:
            return true
        default:
            return false
        }
    }
}
