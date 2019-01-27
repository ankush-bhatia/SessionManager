import Foundation

extension AppDelegate {
    private struct BackgroundSession {
        static var backgroundSessionCompletionHandler: (() -> Void)?
    }
    
    var backgroundSessionCompletionHandler: (() -> Void)? {
        get {
            return BackgroundSession.backgroundSessionCompletionHandler
        }
        set (newValue) {
            BackgroundSession.backgroundSessionCompletionHandler = newValue
        }
    }
}
