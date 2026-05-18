import Foundation

struct ConversionResult {
    var markdown: String
    var standardError: String
}

enum MarkitdownRunnerError: LocalizedError {
    case commandFailed(Int32, String)
    case unreadableOutput

    var errorDescription: String? {
        switch self {
        case .commandFailed(_, let message):
            message.isEmpty ? "markitdown 转换失败。" : message
        case .unreadableOutput:
            "无法读取转换后的 Markdown。"
        }
    }
}

struct MarkitdownRunner: Sendable {
    var repositoryRoot: URL

    func convert(sourceURL: URL, outputURL: URL) async throws -> ConversionResult {
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let stdout = Pipe()
            let stderr = Pipe()

            let shellCommand = self.shellCommand(sourceURL: sourceURL, outputURL: outputURL)
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", shellCommand]
            process.standardOutput = stdout
            process.standardError = stderr

            try process.run()
            process.waitUntilExit()

            let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
            let standardOutput = String(data: stdoutData, encoding: .utf8) ?? ""
            let standardError = String(data: stderrData, encoding: .utf8) ?? ""

            guard process.terminationStatus == 0 else {
                throw MarkitdownRunnerError.commandFailed(process.terminationStatus, standardError + standardOutput)
            }

            guard let markdown = try? String(contentsOf: outputURL, encoding: .utf8) else {
                throw MarkitdownRunnerError.unreadableOutput
            }

            return ConversionResult(markdown: markdown, standardError: standardError)
        }.value
    }

    private func shellCommand(sourceURL: URL, outputURL: URL) -> String {
        let source = sourceURL.path(percentEncoded: false).shellEscaped
        let output = outputURL.path(percentEncoded: false).shellEscaped
        let packageSource = repositoryRoot
            .appending(path: "packages/markitdown/src")
            .path(percentEncoded: false)
            .shellEscaped
        let packageRoot = repositoryRoot
            .appending(path: "packages/markitdown")
            .path(percentEncoded: false)
            .shellEscaped
        let appVenvTool = repositoryRoot
            .appending(path: "apps/MarkitdownMac/.venv/bin/markitdown")
            .path(percentEncoded: false)
            .shellEscaped
        let repoVenvTool = repositoryRoot
            .appending(path: ".venv/bin/markitdown")
            .path(percentEncoded: false)
            .shellEscaped
        let bundledPythons = bundledPythonCandidates()
        let bundledPythonList = bundledPythons
            .ifEmpty(["/__missing_bundled_python__"])
            .map(\.shellEscaped)
            .joined(separator: " ")
        let bundledPythonDiagnostics = bundledPythons.joined(separator: "\\n")

        return """
        for bundled_python in \(bundledPythonList); do
          if [ -x "$bundled_python" ]; then
            "$bundled_python" -m markitdown \(source) -o \(output)
            exit $?
          fi
        done

        if [ -x \(appVenvTool) ]; then
          \(appVenvTool) \(source) -o \(output)
        elif [ -x \(repoVenvTool) ]; then
          \(repoVenvTool) \(source) -o \(output)
        elif command -v markitdown >/dev/null 2>&1; then
          markitdown \(source) -o \(output)
        else
          PYTHON_BIN=""
          for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
            if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' >/dev/null 2>&1; then
              PYTHON_BIN="$candidate"
              break
            fi
          done

          if [ -z "$PYTHON_BIN" ]; then
            echo "Python 3.10 或更高版本是 markitdown 的必要条件。请先安装：brew install python@3.12"
            exit 1
          fi

          if [ ! -f \(packageSource)/markitdown/__main__.py ]; then
            echo "没有找到 App 内置 Python runtime，也没有找到本地 markitdown 源码。请先执行：./script/build_and_run.sh --with-python"
            exit 1
          fi

          PYTHONPATH=\(packageSource) "$PYTHON_BIN" - <<'PY' \(source) \(output) \(packageRoot)
        import runpy
        import sys

        source, output, package_root = sys.argv[1], sys.argv[2], sys.argv[3]
        try:
            import markitdown  # noqa: F401
        except ModuleNotFoundError as exc:
            missing = exc.name or "unknown"
            raise SystemExit(
                "Python 环境缺少 markitdown 依赖："
                + missing
                + "\\n未命中 App 内置 Python runtime。已检查路径：\\n\(bundledPythonDiagnostics)"
                + "\\n请退出旧 App 后，重新运行：./script/build_and_run.sh --with-python --verify"
            )

        sys.argv = ["markitdown", source, "-o", output]
        runpy.run_module("markitdown", run_name="__main__")
        PY
        fi
        """
    }

    private func bundledPythonCandidates() -> [String] {
        var candidates: [URL] = []

        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appending(path: "Python/bin/python"))
            candidates.append(resourceURL.appending(path: "Python/bin/python3"))
        }

        if let executableURL = Bundle.main.executableURL {
            let contentsURL = executableURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
            candidates.append(contentsURL.appending(path: "Resources/Python/bin/python"))
            candidates.append(contentsURL.appending(path: "Resources/Python/bin/python3"))
        }

        return Array(Set(candidates.map { $0.path(percentEncoded: false) })).sorted()
    }
}

private extension String {
    var shellEscaped: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private extension Array {
    func ifEmpty(_ fallback: [Element]) -> [Element] {
        isEmpty ? fallback : self
    }
}
