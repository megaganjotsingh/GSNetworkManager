//
//  MultipartFormEndpoint.swift
//
//  Copyright (c) 2024 Gaganjot Singh (megaganjotsingh@gmail.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public struct MultipartFormEndpoint<Value>: Requestable {
    public typealias Response = Value

    public var path: String
    public var isFullPath: Bool
    public var method: HTTPMethod
    public var headers: [String: String]
    public var useEndpointHeaderOnly: Bool
    public var queryParameters: QueryParameters?
    public let body: HTTPBody? = nil
    public var allowMiddlewares: Bool
    public var form: MultipartFormData?

    public init(
        path: String,
        isFullPath: Bool = false,
        method: HTTPMethod = .post,
        headers: [String: String] = [:],
        useEndpointHeaderOnly: Bool = false,
        queryParameters: QueryParameters? = nil,
        allowMiddlewares: Bool = true,
        form: MultipartFormData
    ) {
        self.path = path
        self.isFullPath = isFullPath
        self.method = method
        self.headers = headers
        self.useEndpointHeaderOnly = useEndpointHeaderOnly
        self.queryParameters = queryParameters
        self.allowMiddlewares = allowMiddlewares
        self.form = form
    }
}

// https://orjpap.github.io/swift/http/ios/urlsession/2024/04/26/Multipart-Form-Requests.html
public struct MultipartFormData {
    private(set) var boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()

    public init() {}

    public init(completion: (inout Self) -> Void) {
        var form = MultipartFormData()
        completion(&form)
        self = form
    }

    public func addTextField(
        named name: String,
        value: String
    ) {
        httpBody.append(textFormField(named: name, value: value))
    }

    private func textFormField(
        named name: String,
        value: String
    ) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=UTF-8\r\n" // Updated to UTF-8
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    public func addDataField(
        named name: String,
        data: Data,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        httpBody.append(dataFormField(named: name, data: data, fileName: fileName, mimeType: mimeType))
    }

    private func dataFormField(
        named name: String,
        data: Data,
        fileName: String? = nil,
        mimeType: String? = nil
    ) -> Data {
        var disposition = "form-data; name=\"\(name)\""
        if let fileName = fileName {
            disposition += "; filename=\"\(fileName)\""
        }

        let fieldData = NSMutableData()
        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: \(disposition)\r\n")
        if let mimeType = mimeType {
            fieldData.append("Content-Type: \(mimeType)\r\n")
        }
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }

    var data: Data? {
        guard
            httpBody.count > 0
        else { return nil }
        let body = NSMutableData(data: httpBody as Data)
        body.append("--\(boundary)--")
        return body as Data
    }
}

extension NSMutableData {
    func append(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}
