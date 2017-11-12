//
//  SongMetaData.swift
//  Volna
//
//  Created by Artem Malyshev on 11/9/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

import Foundation
import AVFoundation

class StationMetadata {
    var artist: String?
    var songTitle: String?
    
    init(from data: AVMetadataItem) {
        parseMetadata(data)
    }
    
    private func parseMetadata(_ data: AVMetadataItem) {
        guard let titleString = data.value as? String  else { return }
        if #available(iOS 11.0, *) {
            let streamInfo = titleString.split(separator: "@", maxSplits: 1)[0].components(separatedBy: " - ")
            guard streamInfo.count > 1 else { return }
            artist = streamInfo[0].trimmingCharacters(in: .whitespacesAndNewlines)
            songTitle = streamInfo[1].trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let encodedData = titleString.data(using: String.Encoding.isoLatin1)
            guard let encodedString = encodedData else { return }
            guard let decodedString = String(data: encodedString, encoding: String.Encoding.utf8), !decodedString.isEmpty else { return }
            let streamInfo = decodedString.split(separator: "@", maxSplits: 1)[0].components(separatedBy: " - ")
            guard streamInfo.count > 1 else { return }
            artist = streamInfo[0].trimmingCharacters(in: .whitespacesAndNewlines)
            songTitle = streamInfo[1].trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
