import Foundation
import TSCBasic

public enum ResourceFileElement: Equatable, Hashable, Codable {
    /// A file path (or glob pattern) to include, a list of file paths (or glob patterns) to exclude, ODR tags list and inclusion
    /// condition.
    /// For convenience, a string literal can be used as an alternate way to specify this option.
    case file(path: AbsolutePath, tags: [String] = [], inclusionCondition: PlatformCondition? = nil)
    /// A directory path to include as a folder reference, ODR tags list and inclusion condition.
    case folderReference(path: AbsolutePath, tags: [String] = [], inclusionCondition: PlatformCondition? = nil)

    case privacyManifest(
        tracking: Bool,
        trackingDomains: [String],
        collectedDataTypes: [[String: Plist.Value]],
        accessedAPITypes: [[String: Plist.Value]]
    )

    public var path: AbsolutePath {
        switch self {
        case let .file(path, _, _):
            return path
        case let .folderReference(path, _, _):
            return path
        case .privacyManifest:
            return ""
        }
    }

    public var isReference: Bool {
        switch self {
        case .file:
            return false
        case .folderReference:
            return true
        case .privacyManifest:
            return false
        }
    }

    public var tags: [String] {
        switch self {
        case let .file(_, tags, _):
            return tags
        case let .folderReference(_, tags, _):
            return tags
        case .privacyManifest:
            return []
        }
    }

    public var inclusionCondition: PlatformCondition? {
        switch self {
        case let .file(_, _, condition):
            return condition
        case let .folderReference(_, _, condition):
            return condition
        case .privacyManifest:
            return nil
        }
    }

    public init(path: AbsolutePath) {
        self = .file(path: path)
    }
}

extension [TuistGraph.ResourceFileElement] {
    public mutating func remove(path: AbsolutePath) {
        guard let index = firstIndex(of: TuistGraph.ResourceFileElement(path: path)) else { return }
        remove(at: index)
    }
}
