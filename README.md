# GSNetworkManager

[![CI Status](https://img.shields.io/travis/megaganjotsingh/GSNetworkManager.svg?style=flat)](https://travis-ci.org/megaganjotsingh/GSNetworkManager)
[![Version](https://img.shields.io/cocoapods/v/GSNetworkManager.svg?style=flat)](https://cocoapods.org/pods/GSNetworkManager)
[![License](https://img.shields.io/cocoapods/l/GSNetworkManager.svg?style=flat)](https://cocoapods.org/pods/GSNetworkManager)
[![Platform](https://img.shields.io/cocoapods/p/GSNetworkManager.svg?style=flat)](https://cocoapods.org/pods/GSNetworkManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Use
let apiClient = ApiClient(
  config: NetworkConfiguration(
    baseURL: URL(string: "https://reqres.in/api/")! 
  )
)
let getEndpoint = Endpoint<Data>(
  path: "users",
  method: .get,
  body: nil
)      
try? await apiClient.request(with: getEndpoint)

## Requirements

## Installation

GSNetworkManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GSNetworkManager'
```

## Author

megaganjotsingh, megaganjotsingh@gmail.com

## License

GSNetworkManager is available under the MIT license. See the LICENSE file for more info.
