#if canImport(WebRTC)
import Foundation
import WebRTC

final class WebRTCAudioManager: NSObject {
    enum Event {
        case connected
        case disconnected
        case failed(String)
    }

    private let factory: RTCPeerConnectionFactory
    private var peerConnections: [String: RTCPeerConnection] = [:]
    private let configuration: RTCConfiguration
    private let constraints: RTCMediaConstraints
    private let audioTrack: RTCAudioTrack
    private var onEvent: ((Event) -> Void)?

    override init() {
        RTCInitializeSSL()
        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)

        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        self.configuration = config

        self.constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: [
            "DtlsSrtpKeyAgreement": "true"
        ])

        let audioSource = factory.audioSource(with: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: [
            "googEchoCancellation": "true",
            "googAutoGainControl": "true",
            "googNoiseSuppression": "true",
            "googTypingNoiseDetection": "true",
            "googAudioMirroring": "false"
        ]))
        self.audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        super.init()
    }

    deinit {
        RTCCleanupSSL()
    }

    func connectPeer(id: String, onEvent: @escaping (Event) -> Void) -> RTCPeerConnection {
        self.onEvent = onEvent
        if let existing = peerConnections[id] {
            return existing
        }
        let pc = factory.peerConnection(with: configuration, constraints: constraints, delegate: self)
        peerConnections[id] = pc
        addAudio(to: pc)
        return pc
    }

    func createOffer(for id: String, completion: @escaping (RTCSessionDescription?, Error?) -> Void) {
        guard let pc = peerConnections[id] else {
            completion(nil, NSError(domain: "WebRTCAudio", code: -1, userInfo: [NSLocalizedDescriptionKey: "No peer"]))
            return
        }
        pc.offer(for: constraints) { sdp, error in
            completion(sdp, error)
        }
    }

    func setRemote(_ sdp: RTCSessionDescription, for id: String, completion: @escaping (Error?) -> Void) {
        guard let pc = peerConnections[id] else {
            completion(NSError(domain: "WebRTCAudio", code: -1, userInfo: [NSLocalizedDescriptionKey: "No peer"]))
            return
        }
        pc.setRemoteDescription(sdp, completionHandler: completion)
    }

    func addIceCandidate(_ candidate: RTCIceCandidate, for id: String) {
        peerConnections[id]?.add(candidate)
    }

    private func addAudio(to pc: RTCPeerConnection) {
        let streamId = "stream-audio"
        pc.add(audioTrack, streamIds: [streamId])
    }
}

extension WebRTCAudioManager: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected, .completed:
            onEvent?(.connected)
        case .failed, .disconnected:
            onEvent?(.failed("ICE state \(newState.rawValue)"))
        default:
            break
        }
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Up to caller to send via signaling.
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}
}
#else
import Foundation

/// Placeholder when WebRTC is not available.
final class WebRTCAudioManager {
    enum Event { case connected, disconnected, failed(String) }
    func connectPeer(id: String, onEvent: @escaping (Event) -> Void) { }
    func createOffer(for id: String, completion: @escaping (Any?, Error?) -> Void) { completion(nil, nil) }
    func setRemote(_ sdp: Any, for id: String, completion: @escaping (Error?) -> Void) { completion(nil) }
    func addIceCandidate(_ candidate: Any, for id: String) { }
}
#endif

