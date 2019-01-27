# HTTP Request Using URL Session

## Description:
- This is a networking library which can be used to make http requests to the server.
- This library uses Apple's URLSession framework.

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
  try HTTPRequest(taskType: .data, config: .default).handleMultipart(withRequestUrl: url, httpMethod: .post, params: params,      files: [file], completion: { (data, error) in
    DispatchQueue.main.async {
      // Turning off activity indicator.
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    if let networkError = error {
     switch networkError.errorCode {
     case .validationError:
       break
     default:
        DispatchQueue.main.async {
          self.showAlert(message: networkError.error)
        }
      return
     }
    }
    guard let response = data else { 
      // Handle Error from Api
      return 
    }
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
  try HTTPRequest(taskType: .data, config: .default).config(timeout: 5.0).handle(withRequestUrl: url, httpMethod: .get, params: nil, completion: { (data, error) in
    DispatchQueue.main.async {
      // Turning off activity indicator.
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    if let networkError = error {
      switch networkError.errorCode {
      case .validationError:
        break
      default:
        // Handle Error
        print(networkError.error)
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


