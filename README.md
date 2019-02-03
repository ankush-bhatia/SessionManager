# SessionManager

## Description:
- It is a light weight networking library which can be used to make http requests to the server.
- This library uses Apple's URLSession framework to handle network calls.

## If you like SessionManager, don't forget to give ★ at the top right of this page. Any kind of suggestions/contributions are welcome.

## Features

- [x] Make http calls with all types of error codes handling.
- [x] Cocoapods Integration.
- [x] Error handling implemented.
- [x] Different API for downloading and uploading files.

## Requirements

- iOS 10.0+
- Xcode 10+

## Installation

Add the following line to your Podfile:

```pod 'SessionManager', '~> 1.0.2'
```

-SessionManager is available on Cocoapods.
-Current version compatible with Swift 4.1.

#### [CocoaPods](https://cocoapods.org):


## Usage:

### Mutlipart Api Request:
##### Creating file object for images/pdf files.

Method: 1
```sh
File(name: documentName, type: MimeType, fileData: Data)
```
> #name - Name of the document required for backend api.
> #type: Mime type of the file. For more information on myme type just follow the MimeType enum in the library.
> #fileData: Accepts Data of file.

Method: 2
```sh
File(name: documentName, type: MimeType, filePath: filePath)
```
> #name - Name of the document required for backend api.
> #type: Mime type of the file. For more information on myme type just follow the MimeType enum in the library.
> #filePath: Requires path of the file saved in the iPhone.

### Multipart Api Request:
##### Creating Request

```sh
let parameters: [String: Any] = ["demo": "done"]
let file: File = File(name: documentName, type: MimeType, fileData: Data)
// Turning on activity indicator.
UIApplication.shared.isNetworkActivityIndicatorVisible = true
do {
try SessionManager(taskType: .data, config: .default).handleMultipart(withRequestUrl: url, httpMethod: .post, params: params, files: [file], completion: { (data, error) in
DispatchQueue.main.async {
// Turning off activity indicator.
UIApplication.shared.isNetworkActivityIndicatorVisible = false
}
if let networkError = error {
switch networkError.errorCode {
case .validationError:
break
case .noInternetConnection:
break
default:
DispatchQueue.main.async {
self.showAlert(message: networkError.error)
}
return
}
}
// No Error Found.
do {
let json = try JSONSerialization.jsonObject(with: response, options:    JSONSerialization.ReadingOptions.mutableContainers)
print(json)
} catch let error {
// Handle Error
print(error)
}
})
} catch HTTPError.handler {
print(HTTPError.handler.failureReason ?? "")
} catch HTTPError.multipartHandler {
print(HTTPError.multipartHandler.failureReason ?? "")
} catch HTTPError.urlCreationFailure {
print(HTTPError.urlCreationFailure.failureReason ?? "")
} catch HTTPError.urlEncodingFailed {
print(HTTPError.urlEncodingFailed.failureReason ?? "")
} catch let error {
print(error.localizedDescription)
}
```

### Normal Api Request:
##### Creating Request

```sh 
let parameters: [String: Any] = ["demo": "done"]
do {
try SessionManager(taskType: .data, config: .default).config(timeout: 5.0).handle(withRequestUrl: url, httpMethod: .get, params: nil, completion: { (data, error) in
DispatchQueue.main.async {
// Turning off activity indicator.
UIApplication.shared.isNetworkActivityIndicatorVisible = false
}
if let networkError = error {
switch networkError.errorCode {
case .validationError:
break
case .noInternetConnection:
break
default:
DispatchQueue.main.async {
self.showAlert(message: networkError.error)
}
return
}
}
// No error found
do {
let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
print(json)
} catch let error {
// Handle Error
print(error)
}
})
// Handle Error from Api
} catch HTTPError.handler {
print(HTTPError.handler.failureReason ?? "")
} catch HTTPError.urlCreationFailure {
print(HTTPError.urlCreationFailure.failureReason ?? "")
} catch HTTPError.urlEncodingFailed {
print(HTTPError.urlEncodingFailed.failureReason ?? "")
} catch let error {
print(error)
}

```




## Contribution
Any contribution towards making it a better library is most welcome.


## Authors
[***Ankush Bhatia**](https://github.com/ankush-bhatia)

## License
This project is licensed under the MIT License -  [LICENSE](LICENSE).






