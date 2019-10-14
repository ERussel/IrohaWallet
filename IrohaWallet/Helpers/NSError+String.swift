import Foundation

extension NSError {
    static func error(message: String, domain: String = "jp.co.bootcamp.example", code: Int = 0) -> NSError {
        return NSError(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
