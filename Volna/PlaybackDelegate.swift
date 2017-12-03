//
//  PlaybackDelegate.swift
//  Volna
//
//  Created by Artem Malyshev on 8/18/17.
//  Copyright © 2017 Artem Malyshev. All rights reserved.
//

protocol PlaybackDelegate {
    func playbackStalled()
    func startPlaybackIndicator()
    func stopPlaybackIndicator()
    func updateStationMetadata(with data: StationMetadata)
}
