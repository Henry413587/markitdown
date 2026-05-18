import Foundation

enum RepositoryLocator {
    static func findRepositoryRoot() -> URL {
        let fileManager = FileManager.default

        var candidates: [URL] = []

        if let environmentPath = ProcessInfo.processInfo.environment["MARKITDOWN_REPOSITORY_ROOT"] {
            candidates.append(URL(fileURLWithPath: environmentPath))
        }

        candidates.append(fileManager.currentDirectoryURL)

        let bundleURL = Bundle.main.bundleURL
        candidates.append(bundleURL)
        candidates.append(bundleURL.deletingLastPathComponent())
        candidates.append(bundleURL.deletingLastPathComponent().deletingLastPathComponent())
        candidates.append(bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())
        candidates.append(bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())

        for candidate in candidates {
            if let root = nearestRepositoryRoot(from: candidate) {
                return root
            }
        }

        return fileManager.currentDirectoryURL
    }

    private static func nearestRepositoryRoot(from startURL: URL) -> URL? {
        var current = startURL.standardizedFileURL
        let fileManager = FileManager.default

        while true {
            let packagePath = current
                .appending(path: "packages/markitdown/src/markitdown/__main__.py")
                .path(percentEncoded: false)
            if fileManager.fileExists(atPath: packagePath) {
                return current
            }

            let parent = current.deletingLastPathComponent()
            if parent == current {
                return nil
            }
            current = parent
        }
    }
}

private extension FileManager {
    var currentDirectoryURL: URL {
        URL(fileURLWithPath: currentDirectoryPath)
    }
}
