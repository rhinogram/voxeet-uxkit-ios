//
//  VTUXConferenceController.swift
//  VoxeetUXKit
//
//  Created by Corentin Larroque on 05/08/2019.
//  Copyright © 2019 Voxeet. All rights reserved.
//

import VoxeetSDK

@objc public class VTUXConferenceController: NSObject {
    private var viewController: ConferenceViewController?

    /// Conference configuration.
    @objc public var configuration = VTUXConferenceControllerConfiguration()

    /// Conference appear animation default starts maximized. If false, the conference will appear minimized.
    @objc public var appearMaximized = true

    /// Video starts with front facing camera by default. If true, the video will start with rear facing camera.
    @objc public var defaultRearCamera = false

    /// Video starts with mic on by default. If true, the video will start with mic off.
    @objc public var defaultMute = false

    /// If true, the conference will behave like a cellular call. if a participant hangs up or declines a call, the caller will be disconnected.
    @objc public var telecom = false {
        didSet {
            if telecom {
                NotificationCenter.default.addObserver(self, selector: #selector(participantUpdated), name: .VTParticipantUpdated, object: nil)
            } else {
                NotificationCenter.default.removeObserver(self, name: .VTParticipantUpdated, object: nil)
            }
        }
    }

    public override init() {
        super.init()

        // Voxeet's socket notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(ownParticipantSwitched), name: .VTOwnParticipantSwitched, object: nil)
        // CallKit notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(callKitSwapped), name: .VTCallKitSwapped, object: nil)
        // Conference status notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(conferenceStatusUpdated), name: .VTConferenceStatusUpdated, object: nil)
    }
}

/*
 *  MARK: - Notifications: Voxeet
 */

extension VTUXConferenceController {
    @objc private func participantUpdated(notification: NSNotification) {
        // Get JSON.
        guard let userInfo = notification.userInfo?.values.first as? Data else { return }

        // Debug.
        print("[VoxeetUXKit] \(String(describing: VoxeetUXKit.self)).\(#function).\(#line)")

        // Stop conference if a participant declines or leaves it.
        if let json = try? JSONSerialization.jsonObject(with: userInfo, options: .mutableContainers) {
            if let jsonDict = json as? [String: Any], let status = jsonDict["status"] as? String, status == "DECLINE" || status == "LEFT" {
                // Update conference state label.
                if status == "DECLINE" {
                    self.viewController?.conferenceStateLabel.text = VTUXLocalized.string("VTUX_CONFERENCE_STATE_DECLINED")
                }

                // Leave current conference.
                VoxeetSDK.shared.conference.leave()
            }
        }
    }

    @objc private func ownParticipantSwitched(notification: NSNotification) {
        // Debug.
        print("[VoxeetUXKit] \(String(describing: VoxeetUXKit.self)).\(#function).\(#line)")

        // Stop the current conference.
        VoxeetSDK.shared.conference.leave()
    }
}

/*
 *  MARK: - Notifications: CallKit
 */

extension VTUXConferenceController {
    @objc private func callKitSwapped(notification: NSNotification) {
        // Remove current conference view from UI before reinitializing it with new conference's participants.
        DispatchQueue.main.async {
            self.viewController?.hide(animated: false) {
                self.viewController?.show(animated: true)
            }
        }
    }
}

/*
 *  MARK: - Notifications: conference status
 */

extension VTUXConferenceController {
    @objc private func conferenceStatusUpdated(notification: NSNotification) {
        guard let status = notification.userInfo?["status"] as? VTConferenceStatus else {
            return
        }

        switch status {
        case .creating, .joining:
            if viewController == nil {
                // Create conference UI and adds it to the window.
                let storyboard = UIStoryboard(name: "VoxeetUXKit", bundle: Bundle(for: type(of: self)))
                viewController = storyboard.instantiateInitialViewController() as? ConferenceViewController
                if let vc = viewController {
                    vc.view.translatesAutoresizingMaskIntoConstraints = false
                    guard let window = UIApplication.shared.keyWindow else { return }
                    window.addSubview(vc.view)
                }

                // Show conference.
                if appearMaximized {
                    viewController?.show()
                } else {
                    viewController?.view.alpha = 0
                    viewController?.minimize(animated: false)
                    UIView.animate(withDuration: 0.25) {
                        self.viewController?.view.alpha = 1
                    }
                }
            }
        case .left, .destroyed, .error:
            // Hide conference.
            viewController?.hide {
                // Remove conference view from superview.
                self.viewController?.view.removeFromSuperview()
                self.viewController = nil
            }
        default: break
        }

        // Update conference UI.
        viewController?.updateConferenceStatus(status)
    }
}
