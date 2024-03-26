import Foundation
import TSCBasic
import TuistCore
import TuistGraph
import TuistSupport
import XcodeProj

/// A project mapper that generates derived privacyManifest files for targets that define it as a dictonary.
public final class GeneratePrivacyManifestProjectMapper: ProjectMapping {
    private let derivedDirectoryName: String
    private let privacyManifestDirectoryName: String

    public init(
        derivedDirectoryName: String = Constants.DerivedDirectory.name,
        privacyManifestDirectoryName: String = Constants.DerivedDirectory.privacyManifest
    ) {
        self.derivedDirectoryName = derivedDirectoryName
        self.privacyManifestDirectoryName = privacyManifestDirectoryName
    }

    // MARK: - ProjectMapping

    public func map(project: Project) throws -> (Project, [SideEffectDescriptor]) {
        logger.debug("Transforming project \(project.name): Synthesizing privacy manifest files'")

        let results = try project.targets
            .reduce(into: (targets: [Target](), sideEffects: [SideEffectDescriptor]())) { results, target in
                let (updatedTarget, sideEffects) = try map(target: target, project: project)
                results.targets.append(updatedTarget)
                results.sideEffects.append(contentsOf: sideEffects)
            }

        return (project.with(targets: results.targets), results.sideEffects)
    }

    // MARK: - Private

    private func map(target: Target, project: Project) throws -> (Target, [SideEffectDescriptor]) {
        // There's nothing to do
        guard let privacyManifest = target.privacyManifest else {
            return (target, [])
        }

        // Get the privacy manifest that needs to be generated
        guard let dictionary = privacyManifestDictionary(
            privacyManifest: privacyManifest
        )
        else {
            return (target, [])
        }
        let data = try PropertyListSerialization.data(
            fromPropertyList: dictionary,
            format: .xml,
            options: 0
        )

        let privacyManifestPath = project.path
            .appending(component: derivedDirectoryName)
            .appending(component: Constants.DerivedDirectory.privacyManifest)
            .appending(component: target.name)
            .appending(component: "PrivacyInfo.xcprivacy")
        let sideEffect = SideEffectDescriptor.file(FileDescriptor(path: privacyManifestPath, contents: data))

        var resources = target.resources
        resources.append(.init(path: privacyManifestPath))

        var newTarget = target
        newTarget.resources = resources

        return (newTarget, [sideEffect])
    }

    private func privacyManifestDictionary(
        privacyManifest: PrivacyManifest
    ) -> [String: Any]? {
        switch privacyManifest {
        case let .dictionary(content):
            return content.mapValues { $0.value }
        default:
            return nil
        }
    }
}
