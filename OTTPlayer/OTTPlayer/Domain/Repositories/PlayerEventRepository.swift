//
//  PlayerEventRepository.swift
//  OTTPlayer
//
//  Created by Ayush on 27/10/26.
//

import Foundation

protocol PlayerEventRepository {
    func record(_ event: PlayerEvent)
}
