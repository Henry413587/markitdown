import Foundation

extension URL {
    var fileSizeDescription: String {
        guard let size = try? resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return "-"
        }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

extension FileManager {
    func uniqueMarkdownURL(for sourceURL: URL, in directory: URL) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension("md")
        var index = 2

        while fileExists(atPath: candidate.path(percentEncoded: false)) {
            candidate = directory
                .appendingPathComponent("\(baseName) \(index)")
                .appendingPathExtension("md")
            index += 1
        }

        return candidate
    }
}
