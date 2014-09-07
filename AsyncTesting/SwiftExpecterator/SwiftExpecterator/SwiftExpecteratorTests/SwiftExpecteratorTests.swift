//
//  SwiftExpecteratorTests.swift
//  SwiftExpecteratorTests
//
//  Created by Sean McCune (BNR) on 8/30/14.
//  Copyright (c) 2014 BNR. All rights reserved.
//

import UIKit
import XCTest

class SwiftExpecteratorTests: XCTestCase {
    
    var pageLoader : Pageloader!
    
    override func setUp() {
        super.setUp()
        self.pageLoader = Pageloader()
    }
    
    override func tearDown() {
        super.tearDown()
    }
        
    func testDownloadingAGoodWebPage() {
        let expectation = expectationWithDescription("High Swift Expectations")
        
        self.pageLoader.requestUrl("http://bignerdranch.com", completion: {
            (page: String?) -> () in
            if let downloadedPage = page {
                XCTAssert(!downloadedPage.isEmpty, "The page is empty")
                expectation.fulfill()
            }
        })
        
        waitForExpectationsWithTimeout(5.0, handler:nil)
    }
}
