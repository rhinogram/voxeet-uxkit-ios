//
//  VoxeetUXKit.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 15/02/2017.
//  Copyright © 2017 Voxeet. All rights reserved.
//

import VoxeetSDK

/*
 *  MARK: - VoxeetUXKit
 */

@objc public class VoxeetUXKit: NSObject {
    /// Voxeet UX kit singleton.
    @objc public static let shared = VoxeetUXKit()

    /// Conference controller.
    @objc public private(set) var conferenceController: VTUXConferenceController?

    /// Conference appear animation default starts maximized. If false, the conference will appear minimized.
    @objc public var appearMaximized = true { /* Will soon be deprecated */
        didSet {
            initialize()
            conferenceController?.appearMaximized = appearMaximized
        }
    }

    /// If true, the conference will behave like a cellular call. if a participant hangs up or declines a call, the caller will be disconnected.
    @objc public var telecom = false { /* Will soon be deprecated */
        didSet {
            initialize()
            conferenceController?.telecom = telecom
        }
    }

    @objc public var defaultRearCamera = false {
        didSet {
            initialize()
            conferenceController?.defaultRearCamera = defaultRearCamera
            }
    }

    @objc public var defaultMute = false {
        didSet {
            initialize()
            conferenceController?.defaultMute = defaultMute
            }
    }

    /*
     *  MARK: Initialization
     */

    override private init() {
        super.init()

        // Debug.
        if let version = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"],
            let build = Bundle(for: type(of: self)).infoDictionary?["CFBundleVersion"] {
            Swift.print("[VoxeetUXKit] \(version).\(build)")
        }
    }

    @objc public func initialize() {
        // Init controllers.
        if conferenceController == nil {
            conferenceController = VTUXConferenceController()
        }
    }
}

@available(*, deprecated, renamed: "VoxeetUXKit") // Deprecated: 1.2.7.
@objc public class VoxeetConferenceKit: NSObject {
    @objc public static let shared = VoxeetUXKit.shared
}
