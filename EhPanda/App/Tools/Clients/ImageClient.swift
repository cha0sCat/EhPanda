//
//  ImageClient.swift
//  EhPanda
//

import Photos
import SwiftUI
import Combine
import SDWebImage
import UniformTypeIdentifiers
import ComposableArchitecture

struct ImageClient {
    let prefetchImages: ([URL]) -> Void
    let saveImageToPhotoLibrary: (UIImage, Bool) async -> Bool
    let downloadImage: (URL) async -> Result<UIImage, Error>
    let retrieveImage: (String) async -> Result<UIImage, Error>
}

extension ImageClient {
    static let live: Self = .init(
        prefetchImages: { urls in
            SDWebImagePrefetcher.shared.prefetchURLs(urls)
        },
        saveImageToPhotoLibrary: { (image, isAnimated) in
            await withCheckedContinuation { continuation in
                if isAnimated, let data = image.sd_imageData() {
                    PHPhotoLibrary.shared().performChanges {
                        let request = PHAssetCreationRequest.forAsset()
                        request.addResource(with: .photo, data: data, options: nil)
                    } completionHandler: { (isSuccess, _) in
                        continuation.resume(returning: isSuccess)
                    }
                } else {
                    PHPhotoLibrary.shared().performChanges {
                        let request = PHAssetCreationRequest.forAsset()
                        let options = PHAssetResourceCreationOptions()
                        options.uniformTypeIdentifier = UTType.png.identifier
                        if let data = image.pngData() {
                            request.addResource(with: .photo, data: data, options: options)
                        }
                    } completionHandler: { (isSuccess, _) in
                        continuation.resume(returning: isSuccess)
                    }
                }
            }
        },
        downloadImage: { url in
            await withCheckedContinuation { continuation in
                SDWebImageDownloader.shared.downloadImage(with: url) { image, _, error, _ in
                    if let image = image {
                        continuation.resume(returning: .success(image))
                    } else if let error = error {
                        continuation.resume(returning: .failure(error))
                    } else {
                        continuation.resume(returning: .failure(AppError.notFound))
                    }
                }
            }
        },
        retrieveImage: { key in
            await withCheckedContinuation { continuation in
                SDImageCache.shared.queryImage(forKey: key, options: [], context: nil) { image, _, _, _ in
                    if let image = image {
                        continuation.resume(returning: .success(image))
                    } else {
                        continuation.resume(returning: .failure(AppError.notFound))
                    }
                }
            }
        }
    )

    func fetchImage(url: URL) async -> Result<UIImage, Error> {
        let cachedImage = await retrieveImage(url.absoluteString)
        switch cachedImage {
        case .success:
            return cachedImage
        case .failure:
            return await downloadImage(url)
        }
    }
}

private final class ImageSaver: NSObject {
    private let completion: (Bool) -> Void

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }

    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSavingImage), nil)
    }
    @objc func didFinishSavingImage(
        _ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer
    ) {
        completion(error == nil)
    }
}

// MARK: API
enum ImageClientKey: DependencyKey {
    static let liveValue = ImageClient.live
    static let previewValue = ImageClient.noop
    static let testValue = ImageClient.unimplemented
}

extension DependencyValues {
    var imageClient: ImageClient {
        get { self[ImageClientKey.self] }
        set { self[ImageClientKey.self] = newValue }
    }
}

// MARK: Test
extension ImageClient {
    static let noop: Self = .init(
        prefetchImages: { _ in },
        saveImageToPhotoLibrary: { _, _ in false },
        downloadImage: { _ in .success(UIImage()) },
        retrieveImage: { _ in .success(UIImage()) }
    )

    static func placeholder<Result>() -> Result { fatalError() }

    static let unimplemented: Self = .init(
        prefetchImages: IssueReporting.unimplemented(placeholder: placeholder()),
        saveImageToPhotoLibrary: IssueReporting.unimplemented(placeholder: placeholder()),
        downloadImage: IssueReporting.unimplemented(placeholder: placeholder()),
        retrieveImage: IssueReporting.unimplemented(placeholder: placeholder())
    )
}
