//
//  CameraHandler.swift
//  AVFoundationVideoproto
//
//  Created by om on 2020/01/08.
//  Copyright © 2020 Ree. All rights reserved.
//

import Foundation
import AVFoundation

 final class CameraHandler {
    // MARK: member
    let session: AVCaptureSession
    
    // MARK: initialize
    init(session: AVCaptureSession){
        self.session = session
    }
    
}
