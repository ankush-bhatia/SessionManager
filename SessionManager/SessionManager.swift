//
//  SessionManager.swift
//  Pods-wrapperURLSession
//
//  Created by Ankush Bhatia on 29/01/19.
//

import Foundation

@objc public protocol SessionManagerDelegate: class {
    @objc optional func didDownload(fileWithProgress progress: Float)
    @objc optional func didFinishedDownloading(atPath path: URL)
    @objc optional func didReceiveResponse(forUploadWith responseObject: URLResponse)
    @objc optional func didUpload(fileWithProgress progress: Float, fileData: Data?)
    @objc func didReceiveError(error: ApiError)
    @objc optional func didUploadFileInBackground(withFileUrl url: URL)
}

public class SessionManager: NSObject {
    // MARK: Properties
    private var request: HTTPRequest?
    public var delegate: SessionManagerDelegate?
    
    // MARK: Intialisers
    public init(taskType: TaskType, config: Config, files: [File]?) {
        super.init()
        self.request = HTTPRequest(taskType: taskType, config: config)
        self.request?.delegate = self
    }
    
    public convenience init(taskType: TaskType, config: Config) {
        self.init(taskType: taskType, config: config, files: [])
    }
}

extension SessionManager {
    // MARK: Functions
    
    /// Handles the multipart api request.
    ///
    /// - Parameters:
    ///   - string: Url for the api request.
    ///   - httpMethod: Http method for the request.
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - files: Files included for the api request.
    ///   - completion: Completion handler of the request.
    /// - Throws: Errors captured in the api request process.
    public func handleMultipart(withRequestUrl string: String, httpMethod: Method, params: [String: Any]?, files: [File]? = nil, completion: @escaping HTTPResult) throws {
        do {
            try self.request!.handleMultipart(withRequestUrl: string, httpMethod: httpMethod, params: params, files: files, completion: completion)
        } catch {
            throw error
        }
    }
    
    /// Handles the non-multipart api request.
    ///
    /// - Parameters:
    ///   - string: Url for the api request.
    ///   - httpMethod: Http method for the request.
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - completion: Completion handler of the request.
    /// - Throws: Errors captured in the api request process.
    public func handle(withRequestUrl string: String, httpMethod: Method, params: [String: Any]?, completion: HTTPResult? = nil) throws {
        do {
            try self.request!.handle(withRequestUrl: string, httpMethod: httpMethod, params: params, completion: completion)
        } catch {
            throw error
        }
        
    }
    
    // MARK: Functions
    
    /// Configures the http request.
    ///
    /// - Parameter timeout: Timeout value in seconds.
    /// - Returns: HTTPRequest object.
    public func config(timeout: Double) -> SessionManager {
        self.request = self.request!.config(timeout: timeout)
        return self
    }
}

extension SessionManager: HTTPRequestDelegate {
    func didReceiveError(error: ApiError) {
        self.delegate?.didReceiveError(error: error)
    }
    
    func didFinishedDownloading(atPath path: URL) {
        self.delegate?.didFinishedDownloading?(atPath: path)
    }
    
    func didDownload(fileWithProgress progress: Float) {
        self.delegate?.didDownload?(fileWithProgress: progress)
    }
    
    // Uploading
    func didUpload(fileWithProgress progress: Float, fileData: Data?) {
        self.delegate?.didUpload?(fileWithProgress: progress, fileData: fileData)
    }
    
    func didReceiveResponse(forUploadWith responseObject: URLResponse) {
        self.delegate?.didReceiveResponse?(forUploadWith: responseObject)
    }
    
    func didUploadFileInBackground(withFileUrl url: URL) {
        self.delegate?.didUploadFileInBackground?(withFileUrl: url)
    }
}

