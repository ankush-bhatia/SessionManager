//
//  HttpRequest.swift
//  URLSession Wrapper
//
//  Created by ANKUSH BHATIA on 03/06/18.
//  Copyright © 2018 Ankush Bhatia. All rights reserved.
//

import UIKit

@objc protocol HTTPRequestDelegate: class {
    @objc optional func didDownload(fileWithProgress progress: Float)
    @objc optional func didFinishedDownloading(atPath path: URL)
    @objc optional func didReceiveResponse(forUploadWith responseObject: URLResponse)
    @objc optional func didUpload(fileWithProgress progress: Float, fileData: Data?)
    @objc func didReceiveError(error: ApiError)
    @objc optional func didUploadFileInBackground(withFileUrl url: URL)
}

public typealias HTTPResult = ((_ data: Data?, _ error: NetworkError?) -> Void)

public struct File {
    private(set) var name: String
    private(set) var type: MimeType
    private(set) var filePath: String?
    private(set) var fileData: Data?
    
    public init(name: String, type: MimeType, filePath: String) {
        self.name = name
        self.type = type
        self.filePath = filePath
    }
    
    public init(name: String, type: MimeType, fileData: Data) {
        self.name = name
        self.type = type
        self.fileData = fileData
    }
}

class Download {
    var task: URLSessionDownloadTask?
    var isDownloading: Bool = false
    var downloadedData: Data?
    var progress: Float = 0
}

class Upload {
    var task: URLSessionUploadTask?
    var uploadedData: Data?
    var progress: Float = 0
    var file: File?
}


public enum MimeType: String {
    case jpegImage = "image/jpg"
    case pdf = "pdf"
}

public enum Method: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case connect = "CONNECT"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
}

public enum Config {
    case `default` // Default configuration.
    case memory // Does not save cookies and data to disk.
    case background(String) // Lets you download and upload data in background mode.
    
    var value: URLSessionConfiguration {
        switch self {
        case .default:
            return .default
        case .background(let value):
            return .background(withIdentifier: "\(Bundle.main.bundleIdentifier ?? "").HttpRequestBackground.\(value)")
        case .memory:
            return .ephemeral
        }
    }
}

public enum TaskType {
    case data // Get Data from server
    case upload // Upload file to server
    case download // Download file from the server
}

class HTTPRequest: NSObject {
    var timeout: Double = 30.0
    var config: Config = .default
    public var taskType: TaskType = .data
    private var dataTask: URLSessionDataTask?
    var requestUrl: URL?
    private var session: URLSession?
    private var files: [File]?
    private var activeDownloads: [URL: Download] = [:]
    private var activeUploads: [URL: Upload] = [:]
    var delegate: HTTPRequestDelegate?
    
    // MARK: Intialisers
    init(taskType: TaskType, config: Config, files: [File]?) {
        self.taskType = taskType
        self.config = config
        self.files = files
        super.init()
        self.session = URLSession(configuration: config.value, delegate: self, delegateQueue: nil)
        self.configure(allowCellularAccess: true, timeoutInterval: nil, shouldWaitForConnectivity: true, requestTimeOut: nil, networkType: .default)
    }
    
    convenience init(taskType: TaskType, config: Config) {
        self.init(taskType: taskType, config: config, files: [])
    }
    
    // MARK: Functions
    
    /// Configures the http request.
    ///
    /// - Parameter timeout: Timeout value in seconds.
    /// - Returns: HTTPRequest object.
    func config(timeout: Double) -> HTTPRequest {
        self.timeout = timeout
        return self
    }
    
    
    /// Add headers to the http request.
    ///
    /// - Parameter headers: Dictionary of values to be set as header.
    /// - Returns: HTTPRequest object.
    func headers(headers: [String: String]) -> HTTPRequest {
        self.config.value.httpAdditionalHeaders = headers
        return self
    }
    
    
    /// Creates multipart request.
    ///
    /// - Parameters:
    ///   - url: Request url.
    ///   - method: Http request method.
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - files: Array of files for the request.
    /// - Returns: URLRequest object.
    private func createMultipartRequest(url: URL, method: Method, params: [String: Any]?, files: [File]? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = method.rawValue
        request.timeoutInterval = self.timeout
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        switch method {
        case .post:
            request.httpBody = bodyForMultipartRequest(params: params, boundary: boundary, files: files)
        default:
            break
        }
        return request
    }
    
    
    
    /// Creates body for the multipart api request.
    ///
    /// - Parameters:
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - boundary: Default boundary value for the multipart request.
    ///   - files: Array of files for the request.
    /// - Returns: Body data to be used for further tasks.
    private func bodyForMultipartRequest(params: [String: Any]?, boundary: String, files: [File]? = nil) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        if let files = files {
            for file in files {
                guard let data = dataFromUrl(file: file) else { break }
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.name)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(file.type.rawValue)\r\n\r\n".data(using: .utf8)!)
                body.append(data)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--".appending(boundary.appending("--")).data(using: .utf8)!)
        return body
    }
    
    /// Handles the multipart api request.
    ///
    /// - Parameters:
    ///   - string: Url for the api request.
    ///   - httpMethod: Http method for the request.
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - files: Files included for the api request.
    ///   - completion: Completion handler of the request.
    /// - Throws: Errors captured in the api request process.
    func handleMultipart(withRequestUrl string: String, httpMethod: Method, params: [String: Any]?, files: [File]? = nil, completion: @escaping HTTPResult) throws {
        guard let encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw HTTPError.urlEncodingFailed
        }
        guard let url = URL(string: encodedString) else {
            throw HTTPError.urlCreationFailure
        }
        self.requestUrl = url
        let request: URLRequest = self.createMultipartRequest(url: url, method: httpMethod, params: params, files: files)
        self.handleTask(request: request) { (data, error) in
            completion(data, error)
        }
    }
    
    
    /// Creates non-multipart request.
    ///
    /// - Parameters:
    ///   - url: Request url.
    ///   - method: Http request method.
    ///   - params: Dictionary of values as parameters for the http request.
    /// - Returns: URLRequest object.
    private func createRquest(url: URL, method: Method, params: [String: Any]?) -> URLRequest {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = method.rawValue
        request.timeoutInterval = self.timeout
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        switch method {
        case .post, .delete, .put, .patch:
            request.httpBody = bodyForRequest(params: params, boundary: boundary)
        case .get:
            break
        default:
            break
        }
        
        return request
    }
    
    
    
    /// Creates body for the non-multipart api request.
    ///
    /// - Parameters:
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - boundary: Default boundary value for the non-multipart request.
    /// - Returns: Body data to be used for further tasks.
    private func bodyForRequest(params: [String: Any]?, boundary: String) -> Data {
        var body = Data()
        //        let boundaryPrefix = "--\(boundary)\r\n"
        //        if let parameters = params {
        //            for (key, value) in parameters {
        //                body.append(boundaryPrefix.data(using: .utf8)!)
        //                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
        //                body.append("\(value)\r\n".data(using: .utf8)!)
        //            }
        //        }
        //        body.append(boundaryPrefix.data(using: .utf8)!)
        //        body.append("\r\n".data(using: .utf8)!)
        //        body.append("--\(boundaryPrefix)--\r\n".data(using: .utf8)!)
        if let parameters = params {
            body = try! JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        }
        return body
    }
    
    /// Handles the non-multipart api request.
    ///
    /// - Parameters:
    ///   - string: Url for the api request.
    ///   - httpMethod: Http method for the request.
    ///   - params: Dictionary of values as parameters for the http request.
    ///   - completion: Completion handler of the request.
    /// - Throws: Errors captured in the api request process.
    func handle(withRequestUrl string: String, httpMethod: Method, params: [String: Any]?, completion: HTTPResult? = nil) throws {
        guard let encodedString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw HTTPError.urlEncodingFailed
        }
        guard let url = URL(string: encodedString) else {
            throw HTTPError.urlCreationFailure
        }
        self.requestUrl = url
        let request: URLRequest = self.createRquest(url: url, method: httpMethod, params: params)
        self.handleTask(request: request) { (data, error) in
            self.invalidateSession()
            completion?(data, error)
        }
    }
    
    
    /// Creates data from file.
    ///
    /// - Parameter file: File object which contains detailed information of the file.
    /// - Returns: Data of the file.
    private func dataFromUrl(file: File) -> Data? {
        if let data = file.fileData {
            return data
        }
        var fileData: Data?
        guard let path = file.filePath else { return nil }
        guard let url = URL(string: path) else { return nil }
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            do {
                let data = try Data(contentsOf: url)
                fileData = data
            } catch let error {
                print(error)
            }
        }
        return fileData
    }
    
    private func fileURLFor(file: File) -> URL? {
        if let data = file.fileData {
            let fileManager = FileManager.default
            let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationUrl = documentPath.appendingPathComponent(file.name)
            do {
                try data.write(to: destinationUrl)
                return destinationUrl
            } catch let error {
                print(error.localizedDescription)
                return nil
            }
        } else if let filePath = file.filePath {
            let url = URL(fileURLWithPath: filePath)
            return url
        } else {
            return nil
        }
    }
    
    /// Configures the http request.
    ///
    /// - Parameters:
    ///   - allowCellularAccess: Boolean value for cellular access.
    ///   - timeoutInterval: Timeout value in seconds.
    ///   - shouldWaitForConnectivity: Boolean value for should wait for connectivity.
    ///   - requestTimeOut: Request time outt value in seconds.
    ///   - networkType: Type of network allowed.
    private func configure(allowCellularAccess: Bool?, timeoutInterval: TimeInterval?, shouldWaitForConnectivity: Bool?, requestTimeOut: TimeInterval?, networkType: NSURLRequest.NetworkServiceType?) {
        let config = self.config.value
        if let allowCellularAccess = allowCellularAccess {
            config.allowsCellularAccess = allowCellularAccess
        }
        if let timeoutInterval = timeoutInterval {
            config.timeoutIntervalForRequest = timeoutInterval
        }
        if let requestTimeOut = requestTimeOut {
            config.timeoutIntervalForResource = requestTimeOut
        }
        if let networkType = networkType {
            config.networkServiceType = networkType
        }
        if let shouldWaitForConnectivity = shouldWaitForConnectivity {
            config.waitsForConnectivity = shouldWaitForConnectivity
        }
    }
    
    
    /// Handles url session task based on the task type.
    ///
    /// - Parameters:
    ///   - request: URLRequest object created to handle requests.
    ///   - completion: Completion handler for the handler of the requests.
    private func handleTask(request: URLRequest, completion: HTTPResult?) {
        switch taskType {
        case .data:
            handleDataTask(request: request) { (data, error) in
                completion!(data, error)
            }
        case .download:
            handleDownloadTask()
        case .upload:
            handleUploadTask(method: .get, file: self.files![0])
        }
    }
    
    
    /// Handles data task of the url session request.
    ///
    /// - Parameters:
    ///   - request: URLSessionRequest object created for the api request.
    ///   - completion: Completion handler to be called at the completion handler of the session.dataTask method.
    private func handleDataTask(request: URLRequest, completion: @escaping HTTPResult) {
        dataTask?.cancel()
        dataTask = session?.dataTask(with: request, completionHandler: { (data, response, error) in
            defer {
                self.dataTask = nil
            }
            if let error = error {
                let error = error as NSError
                if HttpStatusCode.statusCode(forCode: error.code) == HttpStatusCode.timeout {
                    completion(nil, NetworkError(title: "Error!", errorCode: .timeout, error: ApiError.error(forCode: .timeout)))
                } else if HttpStatusCode.statusCode(forCode: error.code) == HttpStatusCode.noInternetConnection {
                    completion(nil, NetworkError(title: "Error!", errorCode: .noInternetConnection, error: ApiError.error(forCode: .noInternetConnection)))
                } else {
                    completion(nil, NetworkError(title: "Error!", errorCode: .somethingWentWrong, error: ApiError.error(forCode: .somethingWentWrong)))
                }
            } else if let data = data {
                self.setCookiesFromResponse(response: response!)
                guard let netwrokError = self.error(forResponse: response!) else {
                    completion(data, nil)
                    return
                }
                completion(data, netwrokError)
            } else {
                completion(nil, NetworkError(title: "Error!", errorCode: .somethingWentWrong, error: ApiError.error(forCode: .somethingWentWrong)))
            }
        })
        dataTask?.resume()
    }
    
    
    
    /// Handles upload tasks.
    ///
    /// - Parameters:
    ///   - method: Http request method type.
    ///   - file: File to be uploaded.
    private func handleUploadTask(method: Method, file: File) {
        guard taskType == .upload else { return }
        guard let url = self.requestUrl else { return }
        let upload = Upload()
        
        // Creating url request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Data from file.
        guard let fileUrl = fileURLFor(file: file) else { return }
        
        // Requesting.
        upload.task = session?.uploadTask(with: request, fromFile: fileUrl)
        upload.file = file
        activeUploads[url] = upload
        upload.task?.resume()
    }
    
    
    /// Handles download tasks.
    private func handleDownloadTask() {
        guard taskType == .download else { return }
        guard let url = self.requestUrl else {
            return
            // HTTPError.invalidURL
        }
        let download = Download()
        download.task = session?.downloadTask(with: url)
        download.isDownloading = true
        activeDownloads[url] = download
        download.task?.resume()
    }
    
    
    /// Errors from the response of the URL Request.
    ///
    /// - Parameter response: URLResponse object from the handler method.
    /// - Returns: Network error from the error received in the api request bases on status codes.
    private func error(forResponse response: URLResponse) -> NetworkError? {
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        let error = NetworkError.errorForStatusCode(errorCode: httpResponse.statusCode)
        return error
    }
    
    
    /// Pauses the download
    ///
    /// - Parameter url: Download url.
    func pauseDownload(url: URL) {
        guard taskType == .download else { return }
        guard let download = activeDownloads[url] else { return }
        if download.isDownloading {
            download.task?.cancel(byProducingResumeData: { (data) in
                download.downloadedData = data
            })
            download.isDownloading = false
        }
    }
    
    
    /// Cancels the download process.
    ///
    /// - Parameter url: Download url.
    func cancelDownload(url: URL) {
        guard taskType == .download else { return }
        guard let download = activeDownloads[url] else { return }
        if download.isDownloading {
            download.task?.cancel()
            activeDownloads[url] = nil
        }
        self.invalidateSession()
    }
    
    
    /// Resumes the download process.
    ///
    /// - Parameter url: Download url.
    func resumeDownload(url: URL) {
        guard taskType == .download else { return }
        guard let download = activeDownloads[url] else { return }
        if let downloadedData = download.downloadedData {
            download.task = session?.downloadTask(withResumeData: downloadedData)
        } else {
            download.task = session?.downloadTask(with: url)
        }
        download.task?.resume()
        download.isDownloading = true
    }
    
    
    /// Cancels the upload process.
    func cancelUpload() {
        guard taskType == .upload else { return }
        guard let url = self.requestUrl else { return }
        guard let upload = self.activeUploads[url] else { return }
        guard let task = upload.task else { return }
        switch task.state {
        case .running:
            task.cancel()
            activeUploads[url] = nil
        default:
            // Handle Errors
            break
        }
        self.invalidateSession()
    }
    
    
    /// Suspends the upload process.
    func pauseUpload() {
        guard taskType == .upload else { return }
        guard let url = self.requestUrl else { return }
        guard let upload = activeUploads[url] else { return }
        guard let task = upload.task else { return }
        switch task.state {
        case .running:
            task.suspend()
        default:
            // Handle Errors
            break
        }
    }
    
    
    /// Resumes the upload process.
    func resumeUpload() {
        guard taskType == .upload else { return }
        guard let url = self.requestUrl else { return }
        guard let upload = activeUploads[url] else { return }
        guard let task = upload.task else { return }
        switch task.state {
        case .suspended:
            task.resume()
        default:
            // Handle errors
            break
        }
    }
    
    
    /// Invalidates all the sessions.
    private func invalidateSession() {
        self.session?.finishTasksAndInvalidate()
    }
    
    // MARK: Cookies
    private func setCookiesFromResponse(response: URLResponse) {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        guard let headerFields = httpResponse.allHeaderFields as? [String: String] else { return }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: response.url!)
        HTTPCookieStorage.shared.setCookies(cookies, for: response.url!, mainDocumentURL: nil)
        for cookie in cookies {
            var cookieProperties = [HTTPCookiePropertyKey: Any]()
            cookieProperties[HTTPCookiePropertyKey.name] = cookie.name
            cookieProperties[HTTPCookiePropertyKey.value] = cookie.value
            cookieProperties[HTTPCookiePropertyKey.domain] = cookie.domain
            cookieProperties[HTTPCookiePropertyKey.path] = cookie.path
            cookieProperties[HTTPCookiePropertyKey.version] = cookie.version
            cookieProperties[HTTPCookiePropertyKey.expires] = cookie.expiresDate
            
            guard let newCookie = HTTPCookie(properties: cookieProperties) else {
                return
            }
            HTTPCookieStorage.shared.setCookie(newCookie)
        }
    }
    
    
    /// Sets cookies to the request url
    ///
    /// - Parameter dict: Dictionary of cookies
    func storeCookies(dict: [String: String]) throws {
        let cookiesStorage = HTTPCookieStorage.shared
        guard let url = self.requestUrl else {
            throw HTTPError.requestURLNil
        }
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: dict, for: url)
        cookiesStorage.setCookies(cookies, for: url, mainDocumentURL: url)
        self.config.value.httpCookieStorage = cookiesStorage
    }
    
    
    /// Reads cookies for URL
    ///
    /// - Parameter url: Request url
    /// - Returns: Array of cookies stored in cookie storage
    func readCookies(forURL url: URL) -> [HTTPCookie] {
        let cookieStorage = HTTPCookieStorage.shared
        let cookies = cookieStorage.cookies(for: url)
        return cookies ?? []
    }
    
    
    /// Delete all the cookies for URL
    ///
    /// - Parameter url: Request URL
    func deleteCookies(forURL url: URL) {
        let cookieStorage = HTTPCookieStorage.shared
        for cookie in readCookies(forURL: url) {
            cookieStorage.deleteCookie(cookie)
        }
    }
}

extension HTTPRequest: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let downloadUrl = downloadTask.originalRequest?.url else {
            return
        }
        //let download = activeDownloads[downloadUrl]
        activeDownloads[downloadUrl] = nil
        let fileManager = FileManager.default
        let documentPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentPath.appendingPathComponent(downloadUrl.lastPathComponent)
        try? fileManager.removeItem(at: destinationUrl)
        do {
            try fileManager.copyItem(at: location, to: destinationUrl)
            self.invalidateSession()
            self.delegate?.didFinishedDownloading?(atPath: destinationUrl)
        } catch let error {
            print("Could not copy file to disk: \(error.localizedDescription)")
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let downloadUrl = downloadTask.originalRequest?.url else {
            return
        }
        let download = activeDownloads[downloadUrl]
        download?.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        //let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: .file)
        self.delegate?.didDownload?(fileWithProgress: download!.progress)
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
}


extension HTTPRequest: URLSessionDelegate, URLSessionDataDelegate {
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        // Need to call this completion handler on the main thread because this function might be called in another thread as stated in the apple documentation of URLSession.
//        DispatchQueue.main.async {
//            if let appdelegate = UIApplication.shared.delegate as? AppDelegate, let completionHandler = appdelegate.backgroundSessionCompletionHandler {
//                appdelegate.backgroundSessionCompletionHandler = nil
//                completionHandler()
//            }
//        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as NSError? else {
            guard let url = checkForBackgroundTaskForFileURL(session, task: task) else {
                return
            }
            self.delegate?.didUploadFileInBackground?(withFileUrl: url)
            self.invalidateSession()
            return
        }
        let statusCode = HttpStatusCode.statusCode(forCode: error.code)
        switch statusCode {
        case .userCancelled:
            // User cancelled the operation
            let apiError = ApiError.error(forCode: statusCode)
            self.delegate?.didReceiveError(error: apiError)
        default:
            break
        }
        self.invalidateSession()
    }
    
    
    private func checkForBackgroundTaskForFileURL(_ session: URLSession, task: URLSessionTask) -> URL? {
        // TODO: - Remove file from the path saved earlier for upload process
        if taskType == .upload {
            guard let url = task.originalRequest?.url else { return nil }
            guard let upload = self.activeUploads[url] else { return nil }
            guard let file = upload.file else { return nil }
            guard let fileUrl = fileURLFor(file: file) else { return nil }
            return fileUrl
        } else {
            return nil
        }
    }
    
    // If the initial handshake with the server requires a connection-level challenge (such as an SSL client certificate).
    //    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    //    }
    //
    //    // If the response indicates that authentication is required.
    //    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    //    }
    //
    //    // If task data is provided from a stream.
    //    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
    //
    //    }
    //
    //    // Reports the progress of the upload.
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard taskType == .upload else {
            return
        }
        guard let uploadUrl = task.currentRequest?.url else {
            return
        }
        let upload = activeUploads[uploadUrl]
        upload?.progress = Float(totalBytesSent)/Float(totalBytesExpectedToSend)
        //let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToSend, countStyle: .file)
        if upload!.progress == 1.0 {
            self.delegate?.didUpload?(fileWithProgress: upload!.progress, fileData: upload!.file!.fileData!)
        } else {
            self.delegate?.didUpload?(fileWithProgress: upload!.progress, fileData: nil)
        }
    }
    
    // Returns the response of the api.( Helpful in case of upload task )
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        //        guard let uploadUrl = dataTask.currentRequest?.url else {
        //            return
        //        }
        //        let upload = activeUploads[uploadUrl]
        //        print("Recievedfjnfksjdflksjdf")
        self.delegate?.didReceiveResponse?(forUploadWith: response)
        completionHandler(.allow)
        self.invalidateSession()
    }
    
    //
    //    // If the response is Http redirection.
    //    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
    //
    //    }
    //
    
}

//extension AppDelegate {
//    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
//        self.backgroundSessionCompletionHandler = completionHandler
//    }
//}

//extension Data {
//    mutating func appendString(string: String) {
//        let data = string.data(using: .utf8, allowLossyConversion: true)
//        self.append(data)
//    }
//}
