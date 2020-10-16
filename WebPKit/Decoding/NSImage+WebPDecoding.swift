//
//  NSImage+WebPDecoding.swift
//  WebPKit
//
//  Created by Tim Oliver on 16/10/20.
//

import Foundation

#if canImport(AppKit)
import AppKit

extension NSImage {

    /// Create a new image object by the decoding
    /// data in the WebP format
    /// - Parameters:
    ///   - webpData: The WebP encoded data to decode
    ///   - scale: The scale factor to scale the content to.
    ///            If nil is specified, the screen scale is used
    convenience init?(webpData: Data, width: CGFloat? = nil, height: CGFloat? = nil,
                      scalingMode: CGImage.WebPScalingMode = .aspectFit) {
        guard let cgImage = try? CGImage.webpImage(data: webpData,
                                                   width: width,
                                                   height: height,
                                                   scalingMode: scalingMode) else { return nil }
        self.init(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
    }

    /// Create a new image object by the decoding
    /// data in the WebP format on disk
    /// - Parameters:
    ///   - url: The WebP file to decode
    ///   - scale: The scale factor to scale the content to.
    ///            If nil is specified, the screen scale is used
    convenience init?(contentsOfWebPFile url: URL, width: CGFloat? = nil, height: CGFloat? = nil,
                      scalingMode: CGImage.WebPScalingMode = .aspectFit) {
        guard let cgImage = try? CGImage.webpImage(contentsOfFile: url,
                                                   width: width,
                                                   height: height,
                                                   scalingMode: scalingMode) else { return nil }
        self.init(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
    }

    /// Load a WebP image file from this app's resources bundle.
    /// If successfully loaded, the image is cached so it can be re-used
    /// on subsequent calls
    /// - Parameters:
    ///   - name: The WebP image's name in the resources bundle
    ///   - bundle: Optionally, the bundle to target (By default, the main bundle is used)
    /// - Returns: The decoded image if successful, or nil if not
    static func webpNamed(_ name: String, bundle: Bundle = Bundle.main) -> NSImage? {
        // Find the non-retina version of the image in the resource bundle
        guard let url = bundle.url(forResource: name,
                                   withExtension: URL.webpFileExtension) else { return nil }

        // Get the size of the non-retina image
        guard let size = CGImage.sizeOfWebP(at: url) else { return nil }

        // Configure a dynamic block to render the image to the supplied size
        let image = NSImage(size: size, flipped: false) { rect -> Bool in
            // Try and decode the image
            guard let cgImage = try? CGImage.webpImage(contentsOfFile: url) else {
                return false
            }

            // Load the image and draw
            let image = NSImage(cgImage: cgImage, size: size)
            image.draw(in: rect)
            return true
        }

        return image
    }
}

#endif
