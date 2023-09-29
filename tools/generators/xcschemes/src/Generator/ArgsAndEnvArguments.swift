import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj
import XCScheme

struct ArgsAndEnvArguments: ParsableArguments {
    @Option(
        parsing: .upToNextOption,
        help: "Target IDs for all targets that have command-line arguments."
    )
    var argsTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of command-line arguments per target that has command-line arguments. \
For example, '--arg-counts 2 3' means the first target (as specified by \
<args-targets>) should include the first two command-line arguments from \
<args>, and the second target should include the next three command-line \
arguments. There must be exactly as many command-line argument counts as there \
are <args-targets> elements, or no command-line argument counts if there are \
no <args-targets> elements. The sum of all of the command-line argument counts \
must equal the number of <args> elements.
"""
    )
    var argCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: "Target IDs for all targets that have environment variables."
    )
    var envTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of environment variables per target that has environment variables. For \
example, '--env-counts 2 3' means the first target (as specified by \
<env-targets>) should include the first two environment variables from <env>, \
and the second target should include the next three command-line arguments. \
There must be exactly as many environment variable counts as there are \
<env-targets> elements, or no environment variable counts if there are no \
<env-targets> elements. The sum of all of the environment variable counts must \
equal half the number of <env> elements.
"""
    )
    var envCounts: [Int] = []

    mutating func validate() throws {
        let argCountsSum = argCounts.reduce(0, +)
        guard argCountsSum == 0 || argCounts.count == argsTargets.count else {
            throw ValidationError("""
<arg-counts> (\(argCounts.count) elements) must have exactly as many elements \
as <args-targets> (\(argsTargets.count) elements).
""")
        }

        let envCountsSum = envCounts.reduce(0, +)
        guard envCountsSum == 0 || envCounts.count == envTargets.count else {
            throw ValidationError("""
<env-counts> (\(envCounts.count) elements) must have exactly as many elements \
as <env-targets> (\(envTargets.count) elements).
""")
        }
    }
}

extension ArgsAndEnvArguments {
    func calculateArgsAndEnv(from url: URL) async throws -> (
        commandLineArguments: [TargetID: [CommandLineArgument]],
        environmentVariables: [TargetID: [EnvironmentVariable]]
    ) {
        let rawArgsAndEnv = try await url.allLines.collect()

        let argCountsSum = argCounts.reduce(0, +)
        let envCountsSum = envCounts.reduce(0, +)

        let expectedSum = argCountsSum + envCountsSum * 2
        guard expectedSum == rawArgsAndEnv.count else {
            throw PreconditionError(message: """
Number of lines in "\(url.path)" (\(rawArgsAndEnv.count)) does not match what
is specified with <arg-counts> (\(argCountsSum)) and <env-counts> \
(\(envCountsSum)). It should equal \(expectedSum)
""")
        }

        var startIndex = rawArgsAndEnv.startIndex

        var argsKeysWithValues: [(TargetID, [CommandLineArgument])] = []
        for targetIndex in argsTargets.indices {
            argsKeysWithValues.append(
                (
                    argsTargets[targetIndex],
                    rawArgsAndEnv.commandLineArgumentsSlicedBy(
                        targetIndex: targetIndex,
                        counts: argCounts,
                        startIndex: &startIndex
                    )
                )
            )
        }

        var envKeysWithValues: [(TargetID, [EnvironmentVariable])] = []
        for targetIndex in envTargets.indices {
            envKeysWithValues.append(
                (
                    envTargets[targetIndex],
                    rawArgsAndEnv.environmentVariablesSlicedBy(
                        targetIndex: targetIndex,
                        counts: envCounts,
                        startIndex: &startIndex
                    )
                )
            )
        }

        return (
            Dictionary(uniqueKeysWithValues: argsKeysWithValues),
            Dictionary(uniqueKeysWithValues: envKeysWithValues)
        )
    }
}

private extension Array where Element == String {
    func commandLineArgumentsSlicedBy<CountsCollection>(
        targetIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index
    ) -> [CommandLineArgument] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let count = counts[targetIndex]
        guard count > 0 else {
            return []
        }

        let endIndex = startIndex.advanced(by: count)
        let range = startIndex ..< endIndex
        startIndex = endIndex

        return self[range].map { value in
            return .init(value: value.nullsToNewlines, enabled: true)
        }
    }

    func environmentVariablesSlicedBy<CountsCollection>(
        targetIndex: Int,
        counts: CountsCollection,
        startIndex: inout Index
    ) -> [EnvironmentVariable] where
        CountsCollection: RandomAccessCollection,
        CountsCollection.Element == Int,
        CountsCollection.Index == Index
    {
        guard !isEmpty else {
            return []
        }

        let count = counts[targetIndex]
        guard count > 0 else {
            return []
        }

        let endIndex = startIndex.advanced(by: count * 2)
        defer {
            startIndex = endIndex
        }

        return stride(from: startIndex, to: endIndex, by: 2).lazy.map {
            return EnvironmentVariable(
                key: self[$0].nullsToNewlines,
                value: self[$0+1].nullsToNewlines,
                enabled: true
            )
        }
    }
}
