//
//  ViewController.swift
//  GSNetworkManager
//
//  Created by megaganjotsingh on 06/17/2024.
//  Copyright (c) 2024 megaganjotsingh. All rights reserved.
//

import UIKit
import GSNetworkManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        apiCall()
        if #available(iOS 13.0, *) {
            Task {
                await get()
            }
        } else {
            // Fallback on earlier versions
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func apiCall() {
        let apiClient = ApiClient(
          config: NetworkConfiguration(
            baseURL: URL(string: "https://reqres.in/api/")!          )
        )
        let postEndpoint = Endpoint<Data>(
          path: "users",
          method: .get,
          body: nil
        )
        
        if #available(iOS 13.0, *) {
            let r = apiClient.request(with: postEndpoint)
                .receive(on: DispatchQueue.main)
                .map({ try? JSONSerialization.jsonObject(with: $0) })
                .eraseToAnyPublisher()
            print(r)
            
        } else {
            // Fallback on earlier versions
            let r = apiClient.request(with: postEndpoint) { respons in
            }
        }
    }
    
    func get() async {
        let apiClient = ApiClient(
          config: NetworkConfiguration(
            baseURL: URL(string: "https://reqres.in/api/")!          )
        )
        let postEndpoint = Endpoint<Data>(
          path: "users",
          method: .get,
          body: nil
        )
        
        if #available(iOS 13.0, *) {
            let re = try? await apiClient.request(with: postEndpoint)
            print(re)
        } else {
            // Fallback on earlier versions
        }
    }
}
