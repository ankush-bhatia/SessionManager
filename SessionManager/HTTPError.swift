//
//  HTTPError.swift
//  
//
//  Created by ANKUSH BHATIA on 01/10/18.
//  Copyright © 2018 Ankush Bhatia. All rights reserved.
//

import UIKit


struct NetworkError: LocalizedError {
    var title: String
    var errorCode: HttpStatusCode
    var error: String
    
    
    init(title: String, errorCode: HttpStatusCode, error: ApiError) {
        self.title = title
        self.errorCode = errorCode
        self.error = error.localizedDescription
    }
    
    static func errorForStatusCode(errorCode: Int) -> NetworkError? {
        let statusCode = HttpStatusCode.statusCode(forCode: errorCode)
        switch statusCode {
        case .success:
            return nil
        default:
            return NetworkError(title: "Error!", errorCode: statusCode, error: ApiError.error(forCode: statusCode))
        }
    }
}

@objc enum ApiError: Int, LocalizedError {
    
    case `default`
    case invalidURL
    case somethingWentWrong
    case unauthorised
    case requestTimeout
    case requiresSecureConnection
    case backgroundSessionInUse
    case backgroundSessionRequiresSharedContainer
    case backgroundSessionDisconnected
    case badServerResponse
    case badUrl
    case callIsActive
    case cancelled
    case cannotCloseFile
    case cannotConnectToHost
    case cannotCreateFile
    case cannotDecodeContentData
    case cannotDecodeRawData
    case cannotFindHost
    case cannotLoadFromNetwork
    case cannotMoveFile
    case cannotOpenFile
    case cannotParseResponse
    case cannotRemoveFile
    case cannotWriteToFile
    case clientCertificateRejected
    case clientCertificateRequired
    case dataLengthExceeded
    case dataNotAllowed
    case dnsLookupFailed
    case downloadingFailedMidstream
    case downloadingFailedToComplete
    case fileDoesNotExist
    case fileIsDirectory
    case fileOutsideSafeArea
    case tooManyRedirects
    case internetRoamingOff
    case networkConnectionLost
    case noPermissionsToReadFile
    case notConnectedToInternet
    case redirectToNonExistentLocation
    case requestBodyExhausted
    case resourceUnavailable
    case secureConnectionFailed
    case badServerCertificateDate
    case unknownServerCertificateRoot
    case invalidServerCertificate
    case untrustedServerCertificate
    case unknownError
    case unsupportedUrl
    case userAuthenticationRequired
    case userCancelledAuthentication
    case zeroByteResource
    case noInternetConnection
    
    /// Error message to be shown to user.
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "The Internet connection appears to be offline. Please check your internet connection."
        case .invalidURL:
            return "Bad Request. Please try again later."
        case .somethingWentWrong:
            return "Something went wrong. Please try again later."
        case .requestTimeout:
            return "Request timed out!. Please try again later."
        case .unauthorised:
            return "You are not allowed to access the account for the credentials provided."
        case .default:
            return "Unknown error occured. Please try again later."
        case .backgroundSessionInUse, .backgroundSessionRequiresSharedContainer, .backgroundSessionDisconnected:
            return "Background services are not configured properly to connect with internet."
        case .callIsActive:
            return "Unable to connect to server in case of active call."
        case .downloadingFailedMidstream, .downloadingFailedToComplete, .noPermissionsToReadFile:
            return "Downloading failed unexpectedly."
        case .fileDoesNotExist, .fileIsDirectory, .fileOutsideSafeArea, .cannotWriteToFile, .cannotRemoveFile,
             .cannotOpenFile, .cannotMoveFile, .cannotCreateFile, .cannotCloseFile:
            return "File system on server returned and unexpected error."
        case .tooManyRedirects, .resourceUnavailable:
            return "Server is unable to handle the requests right now. Please try again later."
        case .internetRoamingOff:
            return "International roaming is disabled on your iPhone right now. Please check with your carrier and try again."
        case .networkConnectionLost, .notConnectedToInternet:
            return "Application is not able to connect with the internet right now. Please check your internet connection and try again later."
        case .secureConnectionFailed, .cannotFindHost, .requiresSecureConnection:
            return "Application is not able to connect to the server right now. Please try again later."
        default:
            return "Unknown error occured. Please try again later."
        }
    }
    
    
    /// Reason for the failure for development purpose only.
    var failureReason: String? {
        switch self {
        case .invalidURL:
            return "No such url exists on the server. Please check again the url of the server api."
        case .somethingWentWrong:
            return "Something went wrong."
        case .unauthorised:
            return "Unauthorised access to the server api."
        case .requestTimeout:
            return "Request taking so much time."
        case .default:
            return "Default type error."
        case .requiresSecureConnection:
            return "App Transport Security disallowed a connection because there is no secure network connection."
        case .backgroundSessionInUse:
            return "An app or app extension attempted to connect to a background session that is already connected to a process."
        case .backgroundSessionRequiresSharedContainer:
            return "The shared container identifier of the URL session configuration is needed but has not been set."
        case .backgroundSessionDisconnected:
            return "The app is suspended or exits while a background data task is processing."
        case .badServerResponse:
            return "The URL Loading system received bad data from the server."
        case .badUrl:
            return "A malformed URL prevented a URL request from being initiated."
        case .callIsActive:
            return "A connection was attempted while a phone call was active on a network that does not support simultaneous phone and data communication (EDGE or GPRS)."
        case .cancelled:
            return "An asynchronous load has been canceled. User cancelled the operation."
        case .cannotConnectToHost:
            return "An attempt to connect to a host failed. "
        case .cannotCloseFile:
            return "A download task couldn’t close the downloaded file on disk."
        case .cannotCreateFile:
            return "A download task couldn’t create the downloaded file on disk because of an I/O failure."
        case .cannotDecodeContentData:
            return "Content data received during a connection request had an unknown content encoding."
        case .cannotDecodeRawData:
            return "Content data received during a connection request could not be decoded for a known content encoding."
        case .cannotFindHost:
            return "The host name for a URL could not be resolved."
        case .cannotLoadFromNetwork:
            return "A specific request to load an item only from the cache could not be satisfied. "
        case .cannotMoveFile:
            return "A NSURLDownload instance was unable to move a downloaded file on disk."
        case .cannotOpenFile:
            return "A NSURLDownload instance was unable to open the downloaded file on disk."
        case .cannotParseResponse:
            return "A response to a connection request could not be parsed."
        case .cannotRemoveFile:
            return "A NSURLDownload instance was unable to remove a downloaded file from disk."
        case .cannotWriteToFile:
            return "A NSURLDownload instance was unable to write to the downloaded file on disk."
        case .clientCertificateRejected:
            return "A server certificate was rejected."
        case .clientCertificateRequired:
            return "A client certificate was required to authenticate an SSL connection during a connection request."
        case .dataLengthExceeded:
            return "The length of the resource data exceeded the maximum allowed."
        case .dataNotAllowed:
            return "The cellular network disallowed a connection."
        case .dnsLookupFailed:
            return "The host address could not be found via DNS lookup."
        case .downloadingFailedMidstream:
            return "A NSURLDownload instance failed to decode an encoded file during the download."
        case .downloadingFailedToComplete:
            return "A NSURLDownload instance failed to decode an encoded file after downloading."
        case .fileDoesNotExist:
            return "A file does not exist."
        case .fileIsDirectory:
            return "A request for an FTP file resulted in the server responding that the file is not a plain file, but a directory."
        case .fileOutsideSafeArea:
            return "An internal file operation failed."
        case .tooManyRedirects:
            return "A redirect loop was detected or when the threshold for number of allowable redirects was exceeded (currently 16)."
        case .internetRoamingOff:
            return "The attempted connection required activating a data context while roaming, but international roaming is disabled."
        case .networkConnectionLost:
            return "A client or server connection was severed in the middle of an in-progress load."
        case .noPermissionsToReadFile:
            return "A resource couldn’t be read because of insufficient permissions."
        case .notConnectedToInternet:
            return "A network resource was requested, but an internet connection has not been established and cannot be established automatically."
        case .redirectToNonExistentLocation:
            return "A redirect was specified by way of server response code, but the server did not accompany this code with a redirect URL."
        case .requestBodyExhausted:
            return "A body stream was needed but the client did not provide one. This impacts clients on iOS that send a POST request using a body stream but do not implement the NSURLSessionTaskDelegate delegate method URLSession:task:needNewBodyStream:."
        case .resourceUnavailable:
            return "A requested resource couldn’t be retrieved."
        case .secureConnectionFailed:
            return "An attempt to establish a secure connection failed for reasons that can’t be expressed more specifically."
        case .badServerCertificateDate:
            return "A server certificate had a date which indicated it had expired, or is not yet valid."
        case .unknownServerCertificateRoot:
            return "A server certificate was not signed by any root server."
        case .invalidServerCertificate:
            return "A server certificate is not yet valid."
        case .untrustedServerCertificate:
            return "A server certificate was signed by a root server that isn’t trusted."
        case .unknownError:
            return "The URL Loading System encountered an error that it can’t interpret."
        case .unsupportedUrl:
            return "A properly formed URL couldn’t be handled by the framework."
        case .userAuthenticationRequired:
            return "Authentication was required to access a resource."
        case .userCancelledAuthentication:
            return "An asynchronous request for authentication has been canceled by the user."
        case .zeroByteResource:
            return "A server reported that a URL has a non-zero content length, but terminated the network connection gracefully without sending any data."
        case .noInternetConnection:
            return "The Internet connection appears to be offline. Please check your internet connection."
        }
    }
    
    
    /// Recovery suggestions for the user.
    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Please try again later."
        case .somethingWentWrong:
            return "Please try again later."
        case .unauthorised:
            return "Please enter valid credentials."
        case .default:
            return "Please try again later."
        case .requestTimeout:
            return "Please check your internet connection and try again."
        default:
            return "Please try again later."
        }
    }
    
    
    /// Helper for the users in case user access help section from the application.
    var helpAnchor: String? {
        switch self {
        case .invalidURL:
            return "Please contact admin."
        case .somethingWentWrong:
            return "Please contact admin."
        case .unauthorised:
            return "Please contact admin."
        case .default:
            return "Please contact admin."
        case .requestTimeout:
            return "Please contact admin."
        default:
            return "Please contact admin."
        }
    }
    
    static func error(forCode code: HttpStatusCode) -> ApiError {
        switch code {
        case .somethingWentWrong:
            return .invalidURL
        case .validationError:
            return .default
        case .badRequest:
            return .invalidURL
        case .unauthorised:
            return .unauthorised
        case .timeout:
            return .requestTimeout
        case .userCancelled:
            return .cancelled
        case .noInternetConnection:
            return .noInternetConnection
        default:
            return .somethingWentWrong
        }
    }
}


enum HTTPError: LocalizedError {
    case handler
    case multipartHandler
    case urlEncodingFailed
    case urlCreationFailure
    case requestURLNil
    
    
    /// Error message to be shown to user.
    var errorDescription: String? {
        return "Something went wrong. Please try again later."
    }
    
    
    /// Reason for the failure for development purpose only.
    var failureReason: String? {
        switch self {
        case .handler:
            return "Api handler has failed unexpectedly."
        case .multipartHandler:
            return "Api multipart handler has failed unexpectedly."
        case .urlEncodingFailed:
            return "Encoding of the url provided has failed unexpectedly."
        case .urlCreationFailure:
            return  "Creation of url from string has failed."
        case .requestURLNil:
            return  "User tried to add cookies before request was generated."
        }
    }
    
    
    /// Recovery suggestions for the user.
    var recoverySuggestion: String? {
        return "Please try again later."
    }
    
    
    /// Helper for the users in case user access help section from the application.
    var helpAnchor: String? {
        switch self {
        case .requestURLNil:
            return "Add cookie after creating request."
        default:
            return "Please contact admin."
        }
        
    }
}

