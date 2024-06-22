//
//  ApiClient+Closure.swift
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

// MARK: - Networking Closure

public extension ApiClient {
    /// Create a request and convert the reponse `Data` to a `Decodable` object
    /// - Parameters:
    ///   - endpoint: The service `Endpoint`
    ///   - decoder: Json Decoder
    ///   - queue: completiuon DispatchQueue
    ///   - completion: response completion
    /// - Returns: Return a cancellable Network Request
    @discardableResult
    func request<D, E>(
        with endpoint: E,
        decoder: JSONDecoder = .default,
        queue: DispatchQueue = .main,
        progressHUD: GSProgressHUD? = nil,
        completion: @escaping (Response<E.Response>) -> Void
    ) -> NetworkCancellable? where D: Decodable, D == E.Response, E: Requestable {
        dataRequest(with: endpoint, queue: queue, progressHUD: progressHUD) { response in
            switch response.result {
            case let .success(data):
                do {
                    let responseObject = try decoder.decode(D.self, from: data)
                    completion(response.convertedTo(result: .success(responseObject)))
                } catch {
                    print(error)
                    completion(response.convertedTo(result: .failure(.parsingFailed)))
                }
            case let .failure(error):
                completion(response.convertedTo(result: .failure(error)))
            }
        }
    }

    /// Create a request which ignore the response `Data`
    /// - Parameters:
    ///   - endpoint: The service `Endpoint`
    ///   - queue: completiuon DispatchQueue
    ///   - completion: response completion
    /// - Returns: Return a cancellable Network Request
    @discardableResult
    func request<E>(
        with endpoint: E,
        queue: DispatchQueue = .main,
        progressHUD: GSProgressHUD? = nil,
        completion: @escaping (Response<E.Response>) -> Void
    ) -> NetworkCancellable? where E: Requestable, E.Response == Data {
        dataRequest(with: endpoint, queue: queue, progressHUD: progressHUD, completion: completion)
    }

    /// Create a request and convert the reponse `Data` to `String`
    /// - Parameters:
    ///   - endpoint: The service `Endpoint`
    ///   - queue: completiuon DispatchQueue
    ///   - completion: response completion
    /// - Returns: Return a cancellable Network Request
    @discardableResult
    func request<E>(
        with endpoint: E,
        queue: DispatchQueue = .main,
        progressHUD: GSProgressHUD? = nil,
        completion: @escaping (Response<E.Response>) -> Void
    ) -> NetworkCancellable? where E: Requestable, E.Response == String {
        dataRequest(with: endpoint, queue: queue, progressHUD: progressHUD) { response in
            switch response.result {
            case let .success(data):
                guard
                    let string = String(data: data, encoding: .utf8)
                else {
                    completion(response.convertedTo(result: .failure(.dataToStringFailure(data: data))))
                    return
                }
                completion(response.convertedTo(result: .success(string)))
            case let .failure(error):
                completion(response.convertedTo(result: .failure(error)))
            }
        }
    }

    /// Create a request which ignore the response `Data`
    /// - Parameters:
    ///   - endpoint: The service `Endpoint`
    ///   - queue: completiuon DispatchQueue
    ///   - completion: response completion
    /// - Returns: Return a cancellable Network Request
    @discardableResult
    func request<E>(
        with endpoint: E,
        queue: DispatchQueue = .main,
        progressHUD: GSProgressHUD? = nil,
        completion: @escaping (Response<E.Response>) -> Void
    ) -> NetworkCancellable? where E: Requestable, E.Response == Void {
        dataRequest(with: endpoint, queue: queue, progressHUD: progressHUD) { response in
            switch response.result {
            case .success:
                completion(response.convertedTo(result: .success(())))
            case let .failure(error):
                guard case .emptyResponse = error else {
                    if let error = response.result.error as? NetworkError {
                        completion(response.convertedTo(result: .failure(error)))
                    } else {
                        completion(response.convertedTo(result: .failure(.networkFailure)))
                    }
                    return
                }
                completion(response.convertedTo(result: .success(())))
            }
        }
    }
}

// MARK: - Main Request Function

extension ApiClient {
    @discardableResult
    func dataRequest<E>(
        with endpoint: E,
        queue: DispatchQueue = .main,
        progressHUD: GSProgressHUD? = nil,
        completion: @escaping (Response<Data>) -> Void
    ) -> NetworkCancellable? where E: Requestable {
        guard let request = try? endpoint.urlRequest(with: config) else {
            completion(
                Response(
                    result: .failure(.urlGeneration),
                    session: session
                )
            )
            return nil
        }
        
        if let url = request.url, !middlewares.isEmpty {
            let pathComponents = url.pathComponents
            do {
                var globalMiddlewares = [Middleware]()
                var pathMiddlewares = [Middleware]()
                
                for middleware in middlewares {
                    if middleware.pathComponent == "/" {
                        globalMiddlewares.append(middleware)
                    } else if pathComponents.contains(middleware.pathComponent) {
                        pathMiddlewares.append(middleware)
                    }
                }
                
                // Apply all global middlewares
                for middleware in globalMiddlewares {
                    try middleware.preRequestCallbak(request)
                }
                
                // Apply path-specific middlewares
                for middleware in pathMiddlewares {
                    try middleware.preRequestCallbak(request)
                }
                
            } catch {
                completion(
                    Response(
                        result: .failure(.middleware(error)),
                        session: session,
                        request: request,
                        response: nil
                    )
                )
                return nil
            }
        }
        
        if endpoint.allowMiddlewares {
            do {
                try applyPreRequestMiddlewares(request: request)
            } catch {
                completion(
                    Response(
                        result: .failure(.middleware(error)),
                        session: session,
                        request: request,
                        response: nil
                    )
                )
                return nil
            }
        }
        
        progressHUD?.show()
        
        return runDataTask(
            endpoint: endpoint,
            queue: queue,
            progressHUD: progressHUD,
            completion: completion
        )
    }
    
    func applyPreRequestMiddlewares(
        request: URLRequest
    ) throws {
        guard let url = request.url, !middlewares.isEmpty else { return }
        
        let pathComponents = url.pathComponents
        
        var globalMiddlewares = [Middleware]()
        var pathMiddlewares = [Middleware]()
        
        for middleware in middlewares {
            if middleware.pathComponent == "/" {
                globalMiddlewares.append(middleware)
            } else if pathComponents.contains(middleware.pathComponent) {
                pathMiddlewares.append(middleware)
            }
        }
        
        // Apply all global middlewares
        for middleware in globalMiddlewares {
            try middleware.preRequestCallbak(request)
        }
        
        // Apply path-specific middlewares
        for middleware in pathMiddlewares {
            try middleware.preRequestCallbak(request)
        }
    }
    
    func runDataTask<E>(
        endpoint: E,
        queue: DispatchQueue = .main,
        progressHUD: GSProgressHUD? = nil,
        retryCount: Int = 0,
        completion: @escaping (Response<Data>) -> Void
    ) -> NetworkCancellable? where E: Requestable {
        func responseBlock(_ response: Response<Data>) {
            queue.async {
                completion(response)
            }
        }
        
        if let request = try? endpoint.urlRequest(with: config) {
            guard retryCount < 2 else {
                responseBlock(
                    Response(
                        result: .failure(
                            .middlewareMaxRetry
                        ),
                        session: session,
                        request: request,
                        response: nil
                    )
                )
                return nil
            }
            
            let task = session?.dataTask(with: request, completionHandler: { [weak self] data, response, error in
                defer {
                    DispatchQueue.main.async {
                        progressHUD?.dismiss()
                    }
                }
                
                guard let self else { return }
                
                // Print cURL
                if self.config.debug, let session = self.session {
                    ApiClient.printCurl(
                        session: session,
                        request: request,
                        response: response,
                        data: data
                    )
                }
                
                // Run postResponse Middlewares
                if endpoint.allowMiddlewares,
                   let url = request.url,
                   !middlewares.isEmpty
                {
                    do {
                        let pathComponents = url.pathComponents
                        
                        // We separate the two to run first the global Middlewares
                        // and then the path specific one
                        var globalMiddlewares = [Middleware]()
                        var pathMiddlewares = [Middleware]()
                        
                        for middleware in middlewares {
                            if middleware.pathComponent == "/" {
                                globalMiddlewares.append(middleware)
                            } else if pathComponents.contains(middleware.pathComponent) {
                                pathMiddlewares.append(middleware)
                            }
                        }
                        
                        // Apply all global middlewares
                        for middleware in globalMiddlewares {
                            let result = try middleware.postResponseCallbak(data, response, error)
                            switch result {
                            case .next:
                                continue
                            case .retryRequest:
                                _ = runDataTask(
                                    endpoint: endpoint,
                                    queue: queue,
                                    progressHUD: progressHUD,
                                    retryCount: retryCount + 1,
                                    completion: completion
                                )
                                return
                            }
                        }
                        
                        // Apply path-specific middlewares
                        for middleware in pathMiddlewares {
                            let result = try middleware.postResponseCallbak(data, response, error)
                            switch result {
                            case .next:
                                continue
                            case .retryRequest:
                                _ = runDataTask(
                                    endpoint: endpoint,
                                    queue: queue,
                                    progressHUD: progressHUD,
                                    retryCount: retryCount + 1,
                                    completion: completion
                                )
                                return
                            }
                        }
                    } catch {
                        responseBlock(
                            Response(
                                result: .failure(.middleware(error)),
                                session: session,
                                request: request,
                                response: response
                            )
                        )
                        return
                    }
                }
                
                // Check error
                if let networkError = error {
                    let networkError = self.getRequestError(
                        data: data,
                        response: response,
                        requestError: networkError
                    )
                    
                    responseBlock(
                        Response(
                            result: .failure(networkError),
                            session: self.session,
                            request: request,
                            response: response
                        )
                    )
                    
                    return
                }
                
                // Make sure have a response
                guard let response else {
                    return
                }
                
                // Check HTTP response status code is within accepted range
                if let error = self.validate(response: response, data: data) {
                    responseBlock(
                        Response(
                            result: .failure(error),
                            session: self.session,
                            request: request,
                            response: response
                        )
                    )
                    return
                }
                
                guard let data else {
                    responseBlock(
                        Response(
                            result: .failure(.emptyResponse),
                            session: self.session,
                            request: request,
                            response: response
                        )
                    )
                    return
                }
                
                // Success Response
                responseBlock(
                    Response(
                        result: .success(data),
                        session: self.session,
                        request: request,
                        response: response
                    )
                )
            })
            
            task?.resume()
            return task
            
        } else {
            responseBlock(
                Response(
                    result: .failure(.urlGeneration),
                    session: session
                )
            )
            return nil
        }
    }
}
