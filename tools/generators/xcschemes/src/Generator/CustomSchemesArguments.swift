import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

struct CustomSchemesArguments: ParsableArguments {
    @Option(
        name: .customLong("s"),
        parsing: .unconditionalSingleValue,
        help: "Name for all of the custom schemes."
    )
    var customSchemes: [String] = []

    // MARK: Test

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Test build-only targets per custom scheme. For example, \
'--test-build-target-counts 2 3' means the first custom scheme (as specified \
by <custom-schemes>) should include the first two build-only targets from \
<test-build-targets>, and the second custom scheme should include the next \
three build-only targets. There must be exactly as many build-only target \
counts as there are custom schemes, or no build-only target counts if there \
are no Test build-only targets among all of the schemes. The sum of all of \
the build-only target counts must equal the number of <test-build-targets> \
elements.
"""
    )
    var testBuildTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test action build-only targets for all of the custom schemes. See \
<test-build-target-counts> for how these build-only targets be distributed \
between the custom schemes.
"""
    )
    var testBuildTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Test action command-line arguments per custom scheme. For example, \
'--test-command-line-argument-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two \
command-line arguments from <test-command-line-arguments>, and the second \
custom scheme should include the next three command-line arguments. There must \
be exactly as many command-line argument counts as there are custom schemes, \
or no command-line argument counts if there are no Test action command-line \
arguments among all of the schemes. The sum of all of the command-line \
argument counts must equal the number of <test-command-line-arguments> elements.
"""
    )
    var testCommandLineArgumentCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test action command-line arguments enabled states for all of the custom \
schemes. There must be exactly as many bools as there are Test command-line \
arguments.
""",
        transform: { $0 == "1" }
    )
    var testCommandLineArgumentEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Address Sanitizer enabled for the test action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testAddressSanitizerEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Thread Sanitizer enabled for the test action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testThreadSanitizerEnabledStates: [Bool] = []

    @Option(
        name: .customLong("test-ub-sanitizer-enabled-states"),
        parsing: .upToNextOption,
        help: """
If the scheme has UB Sanitizer enabled for the Test action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testUBSanitizerEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Test action environment variables per custom scheme. For example, \
'--test-environment-variable-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two environment \
variable pairs from <test-environment-variables>, and the second custom scheme \
should include the next three environment variable pairs. There must be \
exactly as many environment variable counts as there are custom schemes, or no \
environment variable counts if there are no Test action environment variables \
among all of the schemes. The sum of all of the environment variable counts \
must equal half the number of <test-environment-variables> elements.
"""
    )
    var testEnvironmentVariableCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test action environment variable enabled states for all of the custom schemes. \
There must be exactly as many bools as there are Test action environment \
variables.
""",
        transform: { $0 == "1" }
    )
    var testEnvironmentVariableEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Test action environment variables include default ekys and values (e.g. \
'BUILD_WORKSPACE_DIRECTORY'). There must be exactly as many bools as there are \
custom schemes.
""",
        transform: { $0 == "1" }
    )
    var testEnvironmentVariablesIncludeDefaults: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of test targets per custom scheme. For example, \
'--test-target-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two test targets from \
<test-targets>, and the second custom scheme should include the next three \
test targets. There must be exactly as many test target counts as there are \
custom schemes, or no test target counts if there are no test targets among \
all of the schemes. The sum of all of the test target counts must equal the \
number of <test-targets> elements.
"""
    )
    var testTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Test targets for all of the custom schemes. See <test-target-counts> for how \
these test targets be distributed between the custom schemes.
"""
    )
    var testTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the test target should have the 'Enabled' check box checked. There must be \
exactly as many bools as there are test targets.
""",
        transform: { $0 == "1" }
    )
    var testTargetEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Test action should use the Run action's command-line arguments and \
environment variables. There must be exactly as many bools as there are custom \
schemes.
""",
        transform: { $0 == "1" }
    )
    var testUseRunArgsAndEnvEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The Xcode configuration to use for the Test action. There must be exactly as \
many Test action Xcode configurations as there are custom schemes. If an empty \
string, the Test action will use whatever Xcode configuration is chosen for \
the Test action. See <run-xcode-configuration> for more details.
"""
    )
    var testXcodeConfigurations: [String?] = []

    // MARK: Run

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Run build-only targets per custom scheme. For example, \
'--run-build-target-counts 2 3' means the first custom scheme (as specified by \
<custom-schemes>) should include the first two build-only targets from \
<run-build-targets>, and the second custom scheme should include the next \
three build-only targets. There must be exactly as many build-only target
counts as there are custom schemes, or no build-only target counts if there \
are no Run build-only targets among all of the schemes. The sum of all of the \
build-only target counts must equal the number of <run-build-targets> elements.
"""
    )
    var runBuildTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Run action build-only targets for all of the custom schemes. See \
<run-build-target-counts> for how these build-only targets be distributed \
between the custom schemes.
"""
    )
    var runBuildTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Run action command-line arguments per custom scheme. For example, \
'--run-command-line-argument-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two \
command-line arguments from <run-command-line-arguments>, and the second \
custom scheme should include the next three command-line arguments. There must \
be exactly as many command-line argument counts as there are custom schemes, \
or no command-line argument counts if there are no Run action command-line \
arguments among all of the schemes. The sum of all of the command-line \
argument counts must equal the number of <run-command-line-arguments> elements.
"""
    )
    var runCommandLineArgumentCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Run action command-line arguments enabled states for all of the custom \
schemes. There must be exactly as many bools as there are Run command-line \
arguments.
""",
        transform: { $0 == "1" }
    )
    var runCommandLineArgumentEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Address Sanitizer enabled for the Run action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runAddressSanitizerEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has Thread sanitizer enabled for the Run action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runThreadSanitizerEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the scheme has UB Sanitizer enabled for the Run action. There must be \
exactly as many bools as there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runUBSanitizerEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Run action environment variables per custom scheme. For example, \
'--run-environment-variable-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two environment \
variable pairs from <run-environment-variables>, and the second custom scheme \
should include the next three environment variable pairs. There must be \
exactly as many environment variable counts as there are custom schemes, or no \
environment variable counts if there are no Run action environment variables \
among all of the schemes. The sum of all of the environment variable counts \
must equal half the number of <run-environment-variables> elements.
"""
    )
    var runEnvironmentVariableCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Run action environment variable enabled states for all of the custom schemes. \
There must be exactly as many bools as there are Run action environment \
variables.
""",
        transform: { $0 == "1" }
    )
    var runEnvironmentVariableEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Run action environment variables include default ekys and values (e.g. \
'BUILD_WORKSPACE_DIRECTORY'). There must be exactly as many bools as there are \
custom schemes.
""",
        transform: { $0 == "1" }
    )
    var runEnvironmentVariablesIncludeDefaults: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the extension host to use to launch <run-launch-target>. If \
the Run launch target isn't an application extension, use an empty string. If \
this isn't an empty string, <run-launch-target> must also not be an empty \
string.
"""
    )
    var runLaunchExtensionHosts: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the target to launch with the Run action. If the Run action \
doesn't have a launch target, use an empty string. There must be exactly as \
many Run launch targets as there are custom schemes.
"""
    )
    var runLaunchTargets: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The custom working directory for the Run action. There must be exactly as many \
custom working directories as there are custom schemes. If the Run action \
doesn't have a custom working directory, use an empty string.
"""
    )
    var runWorkingDirectories: [String?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The Xcode configuration to use for the Run action. There must be exactly as \
many Run action Xcode configurations as there are custom schemes. If the Run \
action should use the default Xcode configuration, use an empty string.
"""
    )
    var runXcodeConfigurations: [String?] = []

    // MARK: Profile

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Profile build-only targets per custom scheme. For example, \
'--profile-build-target-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two build-only targets \
from <profile-build-targets>, and the second custom scheme should include the \
next three build-only targets. There must be exactly as many build-only target \
counts as there are custom schemes, or no build-only target counts if there \
are no Profile build-only targets among all of the schemes. The sum of all of \
the build-only target counts must equal the number of <profile-build-targets> \
elements.
"""
    )
    var profileBuildTargetCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Profile action build-only targets for all of the custom schemes. See \
<profile-build-target-counts> for how these build-only targets be distributed \
between the custom schemes.
"""
    )
    var profileBuildTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Profile action command-line arguments per custom scheme. For \
example, '--profile-command-line-argument-counts 2 3' means the first custom \
scheme (as specified by <custom-schemes>) should include the first two \
command-line arguments from <profile-command-line-arguments>, and the second \
custom scheme should include the next three command-line arguments. There must \
be exactly as many command-line argument counts as there are custom schemes, \
or no command-line argument counts if there are no Profile action command-line \
arguments among all of the schemes. The sum of all of the command-line \
argument counts must equal the number of <profile-command-line-arguments> \
elements.
"""
    )
    var profileCommandLineArgumentCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Profile action command-line arguments enabled states for all of the custom \
schemes. There must be exactly as many bools as there are Profile command-line \
arguments.
""",
        transform: { $0 == "1" }
    )
    var profileCommandLineArgumentEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Number of Profile action environment variables per custom scheme. For example, \
'--profile-environment-variable-counts 2 3' means the first custom scheme (as \
specified by <custom-schemes>) should include the first two environment \
variable pairs from <run-environment-variables>, and the second custom scheme \
should include the next three environment variable pairs. There must be \
exactly as many environment variable counts as there are custom schemes, or no \
environment variable counts if there are no Profile action environment \
variables among all of the schemes. The sum of all of the environment variable \
counts must equal half the number of <profile-environment-variables> \
elements.
"""
    )
    var profileEnvironmentVariableCounts: [Int] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Profile action environment variable enabled states for all of the custom \
schemes. There must be exactly as many bools as there are Profile action \
environment variables.
""",
        transform: { $0 == "1" }
    )
    var profileEnvironmentVariableEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Profile action environment variables include default ekys and values \
(e.g. 'BUILD_WORKSPACE_DIRECTORY'). There must be exactly as many bools as \
there are custom schemes.
""",
        transform: { $0 == "1" }
    )
    var profileEnvironmentVariablesIncludeDefaults: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the extension host to use to launch <profile-launch-target>. \
If the Profile launch target isn't an application extension, use an empty \
string. If this isn't an empty string, <profile-launch-target> must also not
be an empty string.
"""
    )
    var profileLaunchExtensionHosts: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID of the target to launch with the Profile action. If the Profile \
action doesn't have a launch target, use an empty string. There must be \
exactly as many Profile launch targets as there are custom schemes.
"""
    )
    var profileLaunchTargets: [TargetID?] = []

    @Option(
        parsing: .upToNextOption,
        help: """
If the Profile action should use the Run action's command-line arguments and \
environment variables. There must be exactly as many bools as there are custom \
schemes.
""",
        transform: { $0 == "1" }
    )
    var profileUseRunArgsAndEnvEnabledStates: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The custom working directory for the Profile action. There must be exactly as \
many custom working directories as there are custom schemes. If the Profile \
action doesn't have a custom working directory, use an empty string.
"""
    )
    var profileWorkingDirectories: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The Xcode configuration to use for the Profile action. There must be exactly \
as many Profile action Xcode configurations as there are custom schemes. If \
an empty string, the Profile action will use whatever Xcode configuration is
chosen for the Run action. See <run-xcode-configuration> for more details.
"""
    )
    var profileXcodeConfigurations: [String?] = []

    // MARK: Execution actions

    @OptionGroup var executionActionsArguments: ExecutionActionsArguments

    // MARK: Validation

    mutating func validate() throws {

        // MARK: Test

        let testBuildTargetCountsSum = testBuildTargetCounts.reduce(0, +)
        guard testBuildTargetCountsSum == testBuildTargets.count else {
            throw ValidationError("""
The sum of <test-build-target-counts> (\(testBuildTargetCountsSum)) must \
equal the number of <test-build-targets> elements (\(testBuildTargets.count)).
""")
        }

        guard testBuildTargetCountsSum == 0 ||
                testBuildTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-build-target-counts> (\(testBuildTargetCounts.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        let testCommandLineArgumentCountsSum =
            testCommandLineArgumentCounts.reduce(0, +)
        guard testCommandLineArgumentCountsSum == 0 ||
                testCommandLineArgumentCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-command-line-argument-counts> (\(testCommandLineArgumentCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard testCommandLineArgumentCountsSum ==
                testCommandLineArgumentEnabledStates.count
        else {
            throw ValidationError("""
The number of <test-command-line-argument-enabled-states> elements \
(\(testCommandLineArgumentEnabledStates.count)) must equal the sum of \
<test-command-line-argument-counts> (\(testCommandLineArgumentCountsSum)).
""")
        }

        guard testAddressSanitizerEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<test-address-sanitizer-enabled-states> \
(\(testAddressSanitizerEnabledStates.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testThreadSanitizerEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<test-thread-sanitizer-enabled-states> \
(\(testThreadSanitizerEnabledStates.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testUBSanitizerEnabledStates.count == customSchemes.count else {
            throw ValidationError("""
<test-ub-sanitizer-enabled-states> (\(testUBSanitizerEnabledStates.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        let testEnvironmentVariableCountsSum =
            testEnvironmentVariableCounts.reduce(0, +)
        guard testEnvironmentVariableCountsSum == 0 ||
                testEnvironmentVariableCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-environment-variable-counts> (\(testEnvironmentVariableCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard testEnvironmentVariableCountsSum ==
                testEnvironmentVariableEnabledStates.count
        else {
            throw ValidationError("""
The number of <test-environment-variable-enabled-states> elements \
(\(testEnvironmentVariableEnabledStates.count)) must equal the sum of \
<test-environment-variables-counts> (\(testEnvironmentVariableCountsSum)).
""")
        }

        guard testEnvironmentVariablesIncludeDefaults.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<test-environment-variables-include-defaults> \
(\(testEnvironmentVariablesIncludeDefaults.count) elements) must have exactly \
as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        let testTargetCountsSum = testTargetCounts.reduce(0, +)
        guard testTargetCountsSum == testTargets.count else {
            throw ValidationError("""
The sum of <test-target-counts> (\(testTargetCountsSum)) must equal the number \
of <test-targets> elements (\(testTargets.count)).
""")
        }

        guard testTargetCountsSum == 0 ||
                testTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<test-target-counts> (\(testTargetCounts.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testTargetEnabledStates.count == testTargets.count else {
            throw ValidationError("""
<test-target-enabled-states> (\(testTargetEnabledStates.count) elements) must \
have exactly as many elements as <test-targets> (\(testTargets.count) elements).
""")
        }

        guard testUseRunArgsAndEnvEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<test-use-run-args-and-env-enabled-states> \
(\(testUseRunArgsAndEnvEnabledStates.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testUseRunArgsAndEnvEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<test-use-run-args-and-env-enabled-states> \
(\(testUseRunArgsAndEnvEnabledStates.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard testXcodeConfigurations.count == customSchemes.count else {
            throw ValidationError("""
<test-xcode-configurations> (\(testXcodeConfigurations.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        // MARK: Run

        let runBuildTargetCountsSum = runBuildTargetCounts.reduce(0, +)
        guard runBuildTargetCountsSum == runBuildTargets.count else {
            throw ValidationError("""
The sum of <run-build-target-counts> (\(runBuildTargetCountsSum)) must \
equal the number of <run-build-targets> elements (\(runBuildTargets.count)).
""")
        }

        guard runBuildTargetCountsSum == 0 ||
                runBuildTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<run-build-target-counts> (\(runBuildTargetCounts.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        let runCommandLineArgumentCountsSum =
            runCommandLineArgumentCounts.reduce(0, +)
        guard runCommandLineArgumentCountsSum == 0 ||
                runCommandLineArgumentCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<run-command-line-argument-counts> (\(runCommandLineArgumentCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard runCommandLineArgumentCountsSum ==
                runCommandLineArgumentEnabledStates.count
        else {
            throw ValidationError("""
The number of <run-command-line-argument-enabled-states> elements \
(\(runCommandLineArgumentEnabledStates.count)) must equal the sum of \
<run-command-line-argument-counts> (\(runCommandLineArgumentCountsSum)).
""")
        }

        guard runAddressSanitizerEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<run-address-sanitizer-enabled-states> \
(\(runAddressSanitizerEnabledStates.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard runThreadSanitizerEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<run-thread-sanitizer-enabled-states> \
(\(runThreadSanitizerEnabledStates.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard runUBSanitizerEnabledStates.count == customSchemes.count else {
            throw ValidationError("""
<run-ub-sanitizer-enabled-states> (\(runUBSanitizerEnabledStates.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        let runEnvironmentVariableCountsSum =
            runEnvironmentVariableCounts.reduce(0, +)
        guard runEnvironmentVariableCountsSum == 0 ||
                runEnvironmentVariableCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<run-environment-variable-counts> (\(runEnvironmentVariableCounts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard runEnvironmentVariableCountsSum ==
                runEnvironmentVariableEnabledStates.count
        else {
            throw ValidationError("""
The number of <run-environment-variable-enabled-states> elements \
(\(runEnvironmentVariableEnabledStates.count)) must equal the sum of \
<run-environment-variables-counts> (\(runEnvironmentVariableCountsSum)).
""")
        }

        guard runEnvironmentVariablesIncludeDefaults.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<run-environment-variables-include-defaults> \
(\(runEnvironmentVariablesIncludeDefaults.count) elements) must have exactly \
as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard runLaunchExtensionHosts.count == customSchemes.count else {
            throw ValidationError("""
<run-launch-extension-hosts> (\(runLaunchExtensionHosts.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard runLaunchTargets.count == customSchemes.count else {
            throw ValidationError("""
<run-launch-targets> (\(runLaunchTargets.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard runWorkingDirectories.count == customSchemes.count else {
            throw ValidationError("""
<run-working-directories> (\(runWorkingDirectories.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard runXcodeConfigurations.count == customSchemes.count else {
            throw ValidationError("""
<run-xcode-configurations> (\(runXcodeConfigurations.count) elements) must \
have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        // MARK: Profile

        let profileBuildTargetCountsSum = profileBuildTargetCounts.reduce(0, +)
        guard profileBuildTargetCountsSum == profileBuildTargets.count
        else {
            throw ValidationError("""
The sum of <profile-build-target-counts> (\(profileBuildTargetCountsSum)) \
must equal the number of <profile-build-targets> elements \
(\(profileBuildTargets.count)).
""")
        }

        guard profileBuildTargetCountsSum == 0 ||
                profileBuildTargetCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<profile-build-target-counts> (\(profileBuildTargetCounts.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        let profileCommandLineArgumentCountsSum =
            profileCommandLineArgumentCounts.reduce(0, +)
        guard profileCommandLineArgumentCountsSum == 0 ||
                profileCommandLineArgumentCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<profile-command-line-argument-counts> \
(\(profileCommandLineArgumentCounts.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileCommandLineArgumentCountsSum ==
                profileCommandLineArgumentEnabledStates.count
        else {
            throw ValidationError("""
The number of <profile-command-line-argument-enabled-states> elements \
(\(profileCommandLineArgumentEnabledStates.count)) must equal the sum of \
<profile-command-line-argument-counts> (\(profileCommandLineArgumentCountsSum)).
""")
        }

        let profileEnvironmentVariableCountsSum =
            profileEnvironmentVariableCounts.reduce(0, +)
        guard profileEnvironmentVariableCountsSum == 0 ||
                profileEnvironmentVariableCounts.count == customSchemes.count
        else {
            throw ValidationError("""
<profile-environment-variable-counts> \
(\(profileEnvironmentVariableCounts.count) elements) must have exactly as many \
elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileEnvironmentVariableCountsSum ==
                profileEnvironmentVariableEnabledStates.count
        else {
            throw ValidationError("""
The number of <profile-environment-variable-enabled-states> elements \
(\(profileEnvironmentVariableEnabledStates.count)) must equal the sum of \
<profile-environment-variables-counts> (\(profileEnvironmentVariableCountsSum)).
""")
        }

        guard profileEnvironmentVariablesIncludeDefaults.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<profile-environment-variables-include-defaults> \
(\(profileEnvironmentVariablesIncludeDefaults.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileLaunchExtensionHosts.count == customSchemes.count else {
            throw ValidationError("""
<profile-launch-extension-hosts> (\(profileLaunchExtensionHosts.count) \
elements) must have exactly as many elements as <custom-schemes> \
(\(customSchemes.count) elements).
""")
        }

        guard profileLaunchTargets.count == customSchemes.count else {
            throw ValidationError("""
<profile-launch-targets> (\(profileLaunchTargets.count) elements) must have \
exactly as many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileUseRunArgsAndEnvEnabledStates.count ==
                customSchemes.count
        else {
            throw ValidationError("""
<profile-use-run-args-and-env-enabled-states> \
(\(profileUseRunArgsAndEnvEnabledStates.count) elements) must have exactly as \
many elements as <custom-schemes> (\(customSchemes.count) elements).
""")
        }

        guard profileWorkingDirectories.count ==
                customSchemes.count
            else {
            throw ValidationError("""
<profile-working-directories> (\(profileWorkingDirectories.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }

        guard profileXcodeConfigurations.count == customSchemes.count else {
            throw ValidationError("""
<profile-xcode-configurations> (\(profileXcodeConfigurations.count) elements) \
must have exactly as many elements as <custom-schemes> (\(customSchemes.count) \
elements).
""")
        }
    }
}
