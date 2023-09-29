import ArgumentParser
import Foundation
import GeneratorCommon
import PBXProj

struct ExecutionActionsArguments: ParsableArguments {
    @Option(
        name: .customLong("e"),
        parsing: .unconditionalSingleValue,
        help: "Scheme name for all of the execution actions."
    )
    var executionActions: [String] = []

    @Option(
        parsing: .upToNextOption,
        help: """
Whether the execution action is pre action. There must be as many bools as \
there are execution actions.
""",
        transform: { $0 == "1" }
    )
    var executionActionIsPreActions: [Bool] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The action (i.e. 'build', 'test', 'run', or 'profile') all execution actions \
are associated with. There must be as many values as there are execution \
actions.
"""
    )
    var executionActionActions: [SchemeInfo.ExecutionAction.Action] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The target ID all execution actions are associated with. There must be as many \
target IDs as there are execution actions.
"""
    )
    var executionActionTargets: [TargetID] = []

    @Option(
        parsing: .upToNextOption,
        help: """
The order within an action the execution action should be placed. Use an empty \
string for an unspecified order. There must be as many integers as there are \
execution actions.
"""
    )
    var executionActionOrders: [Int?] = []

    // MARK: Validation

    mutating func validate() throws {
        guard executionActionIsPreActions.count == executionActions.count else {
            throw ValidationError("""
<execution-action-is-pre-actions> (\(executionActionIsPreActions.count) \
elements) must have exactly as many elements as <e> (\(executionActions.count) \
elements).
""")
        }

        guard executionActionActions.count == executionActions.count else {
            throw ValidationError("""
<execution-action-actions> (\(executionActionActions.count) elements) must \
have exactly as many elements as <e> (\(executionActions.count) elements).
""")
        }

        guard executionActionTargets.count == executionActions.count else {
            throw ValidationError("""
<execution-action-targets> (\(executionActionTargets.count) elements) must \
have exactly as many elements as <e> (\(executionActions.count) elements).
""")
        }

        guard executionActionOrders.count == executionActions.count else {
            throw ValidationError("""
<execution-action-orders> (\(executionActionOrders.count) elements) must have \
exactly as many elements as <e> (\(executionActions.count) elements).
""")
        }
    }
}

// MARK: - ExecutionActions

extension ExecutionActionsArguments {
    /// Maps scheme name -> `[SchemeInfo.ExecutionAction]`.
    func calculateExecutionActions(
        from url: URL,
        targetsByID: [TargetID: Target]
    ) async throws -> [
        String: [SchemeInfo.ExecutionAction]
    ] {
        let rawTitlesAndScriptText = try await url.allLines.collect()

        var ret: [String: [SchemeInfo.ExecutionAction]] = [:]

        for executionActionIndex in executionActions.indices {
            ret[
                executionActions[executionActionIndex],
                default: []
            ].append(
                .init(
                    title: rawTitlesAndScriptText[executionActionIndex * 2]
                        .nullsToNewlines,
                    scriptText:
                        rawTitlesAndScriptText[executionActionIndex * 2 + 1]
                            .nullsToNewlines,
                    action: executionActionActions[executionActionIndex],
                    isPreAction:
                        executionActionIsPreActions[executionActionIndex],
                    target: try targetsByID.value(
                        for: executionActionTargets[executionActionIndex],
                        context: "Execution action associated target ID"
                    ),
                    order: executionActionOrders[executionActionIndex]
                )
            )
        }

        return ret
    }
}
