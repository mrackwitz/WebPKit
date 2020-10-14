//
//  CGImage+WebPDecoding.swift
//  WebPKit
//
//  Created by Tim Oliver on 15/10/20.
//

import Foundation
import CoreGraphics

#if canImport(WebP)
import WebP.Decoder
#endif

/// Errors that can potentially occur when
/// tying to decode WebP data
enum WebPDecodingError: UInt32, Error {
    // VP8_STATUS errors
    case ok=0
    case outOfMemory
    case invalidParam
    case bitstreamError
    case unsupportedFeature
    case suspended
    case userAbort
    case notEnoughData

    // CGImage decode errors
    case invalidHeader=100
    case initConfigFailed
    case imageRenderFailed
}

/// Extends CGImage with the ability
/// to decode images from the WebP file format
extension CGImage {

    /// Decode a WebP image from memory and return it as a CGImage
    /// - Parameter data: The data to decode
    /// - Throws: If the data was unabled to be decoded
    /// - Returns: The decoded image as a CGImage
    public static func webpImage(from data: Data) throws -> CGImage {
        var config = WebPDecoderConfig()
        var width: Int32 = 0, height: Int32 = 0

        // Check this is a valid WebP image stream, and retrieve the properties we need
        let result = data.withUnsafeBytes { ptr -> Bool in
            guard let boundPtr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return false }
            return (WebPGetInfo(boundPtr, ptr.count, &width, &height) != 0)
        }
        guard result == true else { throw WebPDecodingError.invalidHeader }

        // Init the config
        guard WebPInitDecoderConfig(&config) != 0 else { throw WebPDecodingError.initConfigFailed }
        config.output.colorspace = MODE_RGBA;
        config.options.bypass_filtering = 1;
        config.options.no_fancy_upsampling = 1;
        config.options.use_threads = 1;

        // Decode the image
        let status = data.withUnsafeBytes { ptr -> VP8StatusCode in
            guard let boundPtr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return VP8_STATUS_INVALID_PARAM }
            return WebPDecode(boundPtr, ptr.count, &config)
        }
        guard status == VP8_STATUS_OK else { throw WebPDecodingError(rawValue: status.rawValue)! }

        // Convert the decoded pixel data to a CGImage
        let releaseData: CGDataProviderReleaseDataCallback = {info, data, size in data.deallocate() }
        let bytesPerRow = 4
        let dataProvider = CGDataProvider(dataInfo: &config,
                                          data: config.output.u.RGBA.rgba,
                                          size: Int(config.output.width * config.output.height) * bytesPerRow,
                                          releaseData: releaseData)

        let colorspace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.last.rawValue)
        let renderingIntent = CGColorRenderingIntent.defaultIntent

        guard let imageRef = CGImage(width: Int(config.output.width),
                               height: Int(config.output.height),
                               bitsPerComponent: 8,
                               bitsPerPixel: 32,
                               bytesPerRow: 4 * Int(config.output.width),
                               space: colorspace,
                               bitmapInfo: bitmapInfo,
                               provider: dataProvider!,
                               decode: nil,
                               shouldInterpolate: false,
                               intent: renderingIntent) else { throw WebPDecodingError.imageRenderFailed }

        return imageRef
    }

}
