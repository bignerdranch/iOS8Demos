//
//  Pageloader.swift
//  SwiftExpecterator
//
//  Created by Sean McCune (BNR) on 8/30/14.
//  Copyright (c) 2014 BNR. All rights reserved.
//

import Foundation

class Pageloader {
    func requestUrl(url: String, completion: (String?) -> ()) {
        
        let urlSession = NSURLSession.sharedSession()

        let task = urlSession.dataTaskWithURL(
            NSURL.URLWithString(url),
            completionHandler: { (data, response, error) -> Void in

                if response == nil || data == nil {
                    if error != nil {
                        println("Error: \(error)")
                    }
                    return
                }
                
                let httpResponse = response as NSHTTPURLResponse
                
                println("Status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    let page = NSString(data: data, encoding: NSUTF8StringEncoding) as String
                    completion(page)
                }
        })
        
        task.resume()
    }
}