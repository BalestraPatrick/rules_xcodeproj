import PathKit
import XcodeProj

struct Project: Equatable, Decodable {
    let name: String
    let bazelWorkspaceName: String
    let label: String
    let configuration: String
    let buildSettings: [String: BuildSetting]
    var targets: [TargetID: Target]
    let targetMerges: [TargetID: Set<TargetID>]
    let invalidTargetMerges: [TargetID: Set<TargetID>]
    let extraFiles: Set<FilePath>
    let bazelWorkspaceName: String
}

struct Target: Equatable, Decodable {
    let name: String
    let label: String
    let configuration: String
    var packageBinDir: Path
    let platform: Platform
    let product: Product
    var isSwift: Bool
    let testHost: TargetID?
    var buildSettings: [String: BuildSetting]
    var searchPaths: SearchPaths
    var modulemaps: [FilePath]
    var swiftmodules: [FilePath]
    let resourceBundles: Set<FilePath>
    var inputs: Inputs
    var linkerInputs: LinkerInputs
    var infoPlist: FilePath?
    var entitlements: FilePath?
    var dependencies: Set<TargetID>
    var outputs: Outputs
}

struct Product: Equatable, Decodable {
    let type: PBXProductType
    let name: String
    let path: FilePath
}

struct Platform: Equatable, Decodable {
    enum OS: String, Decodable {
        case macOS = "macos"
        case iOS = "ios"
        case tvOS = "tvos"
        case watchOS = "watchos"
    }

    let os: OS
    let arch: String
    let minimumOsVersion: String
    let environment: String?
}
