import Foundation
import os.log

struct Logger {
    enum LogLevel {
        case debug
        case info
        case warning
        case error
        
        var symbol: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
    
    private let category: String
    private let osLog: OSLog
    
    init(category: String) {
        self.category = category
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.gymbuddy", category: category)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(.debug, message, file: file, function: function, line: line)
        #endif
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    private func log(_ level: LogLevel, _ message: String, file: String, function: String, line: Int) {
        let filename = (file as NSString).lastPathComponent
        let logMessage = "\(level.symbol) [\(category)] \(filename):\(line) \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log(.debug, log: osLog, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: osLog, "%{public}@", logMessage)
        case .warning:
            os_log(.default, log: osLog, "%{public}@", logMessage)
        case .error:
            os_log(.error, log: osLog, "%{public}@", logMessage)
        }
    }
} 