//
//  WebPDecodingDataTests.swift
//  WebPKit
//
//  Created by Tim Oliver on 15/10/20.
//

import XCTest

class WebPDecodingDataTests: WebPDecodingTests {

    // Test checking the file's path extension
    func testDataContentsCheck() {
        XCTAssertTrue(losslessWebPFileData.isWebP)
        XCTAssertTrue(lossyWebPFileData.isWebP)
    }

    // Test an incorrect data stream
    func testInvalidData() {
        let data = "InvalidData".data(using: .ascii)!
        XCTAssertFalse(data.isWebP)
    }
}
