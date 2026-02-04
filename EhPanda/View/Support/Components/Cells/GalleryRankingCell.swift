//
//  GalleryRankingCell.swift
//  EhPanda
//

import SwiftUI
import SDWebImageSwiftUI

struct GalleryRankingCell: View {
    private let gallery: Gallery
    private let ranking: Int

    init(gallery: Gallery, ranking: Int) {
        self.gallery = gallery
        self.ranking = ranking
    }

    var body: some View {
        HStack {
            WebImage(url: gallery.coverURL, context: [.imageThumbnailPixelSize: NSValue(cgSize: CGSize(
                width: Defaults.ImageSize.rowW * 0.75,
                height: Defaults.ImageSize.rowH * 0.75
            ))]) { image in
                image.defaultModifier().scaledToFill()
            } placeholder: {
                Placeholder(style: .activity(ratio: Defaults.ImageSize.headerAspect))
            }
            .transition(.fade(duration: 0.25))
            .frame(width: Defaults.ImageSize.rowW * 0.75, height: Defaults.ImageSize.rowH * 0.75)
            .cornerRadius(2)
            Text(String(ranking)).fontWeight(.medium).font(.title2).padding(.horizontal)
            VStack(alignment: .leading) {
                Text(gallery.trimmedTitle).bold().lineLimit(2).fixedSize(horizontal: false, vertical: true)
                if let uploader = gallery.uploader {
                    Text(uploader).foregroundColor(.secondary).lineLimit(1)
                }
            }
            .font(.caption)
            Spacer()
        }
    }
}

struct GalleryRankingCell_Previews: PreviewProvider {
    static var previews: some View {
        GalleryRankingCell(gallery: .preview, ranking: 1)
            .previewLayout(.fixed(width: 300, height: 100))
            .preferredColorScheme(.dark)
    }
}
