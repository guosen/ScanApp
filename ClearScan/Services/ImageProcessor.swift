import CoreImage
import UIKit

enum ImageProcessor {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func processedImage(
        from source: UIImage,
        rotationDegrees: Int,
        filter: PageFilter
    ) -> UIImage {
        var image = normalizeOrientation(source)
        image = rotate(image, degrees: rotationDegrees)
        return applyFilter(filter, to: image) ?? image
    }

    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    static func rotate(_ image: UIImage, degrees: Int) -> UIImage {
        let normalized = ((degrees % 360) + 360) % 360
        guard normalized != 0 else { return image }
        let radians = CGFloat(normalized) * .pi / 180
        var newSize = image.size
        if normalized == 90 || normalized == 270 {
            newSize = CGSize(width: image.size.height, height: image.size.width)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return image }
        ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        ctx.rotate(by: radians)
        let drawRect = CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        )
        image.draw(in: drawRect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    static func applyFilter(_ filter: PageFilter, to image: UIImage) -> UIImage? {
        guard filter != .original,
              let ciImage = CIImage(image: image) else { return image }

        let output: CIImage?
        switch filter {
        case .original:
            return image
        case .enhanced:
            output = ciImage
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputBrightnessKey: 0.04,
                    kCIInputContrastKey: 1.12,
                    kCIInputSaturationKey: 0.05
                ])
                .applyingFilter("CIUnsharpMask", parameters: [
                    kCIInputRadiusKey: 2.0,
                    kCIInputIntensityKey: 0.5
                ])
        case .blackAndWhite:
            output = ciImage
                .applyingFilter("CIPhotoEffectNoir")
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 1.25
                ])
        case .grayscale:
            output = ciImage.applyingFilter("CIPhotoEffectMono")
        }

        guard let ciOutput = output,
              let cgImage = context.createCGImage(ciOutput, from: ciOutput.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
}
