import Foundation

/// A deterministic host for the synthetic gallery recipe, not a RhineDesign API.
/// There is no transport, persistence, permission grant or automatic retry here.
@MainActor
final class AgentSessionModel {
    enum Connection: String { case connecting, connected, offline }
    enum Run: String { case idle, running, stopRequested, stopped }
    enum Send: String { case idle, awaitingAcceptance, unknown, accepted, rejected }
    enum AuthorizationStatus: String { case pending, decisionPending, allowedOnce, denied, withdrawn }
    enum AuthorizationDecision: String { case allowOnce, deny }

    struct Submission: Equatable {
        let id: UUID
        let text: String
    }

    struct Authorization: Equatable {
        let id: UUID
        let context: String
        var status: AuthorizationStatus
        var decision: AuthorizationDecision?
        var decisionID: UUID?

        var isUnresolved: Bool { status == .pending || status == .decisionPending }
    }

    private(set) var connection: Connection = .connected
    private(set) var run: Run = .idle
    private(set) var runID: UUID?
    private(set) var stopRequestAccepted = false
    private(set) var send: Send = .idle
    private(set) var submission: Submission?
    private(set) var authorization: Authorization?
    private(set) var isInBackground = false
    var draft = "" {
        didSet {
            if oldValue != draft { draftRevision += 1 }
        }
    }

    private var draftRevision: UInt64 = 0
    private var submissionDraftRevision: UInt64?
    private var finishedAuthorizationIDs: Set<UUID> = []

    var canSend: Bool {
        connection == .connected && !isInBackground &&
        send != .awaitingAcceptance && send != .unknown &&
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Snapshot the exact text once. Unknown delivery is locked until reconciled.
    @discardableResult
    func requestSend() -> Submission? {
        guard canSend else { return nil }
        let attempt = Submission(id: UUID(), text: draft)
        submission = attempt
        submissionDraftRevision = draftRevision
        send = .awaitingAcceptance
        return attempt
    }

    /// Return the accepted text once for the host's transcript to append.
    /// A stale acknowledgement must never erase a replacement draft.
    @discardableResult
    func resolveSend(id: UUID, accepted: Bool) -> String? {
        guard let submission, submission.id == id,
              send == .awaitingAcceptance || send == .unknown else { return nil }
        send = accepted ? .accepted : .rejected
        guard accepted else { return nil }
        if draftRevision == submissionDraftRevision && draft == submission.text {
            draft = ""
        }
        return submission.text
    }

    @discardableResult
    func markSendUnknown(id: UUID) -> Bool {
        guard submission?.id == id, send == .awaitingAcceptance else { return false }
        send = .unknown
        return true
    }

    func disconnect() {
        connection = .offline
        if send == .awaitingAcceptance { send = .unknown }
    }

    func enterBackground() {
        isInBackground = true
        disconnect()
    }

    func enterForeground() {
        isInBackground = false
        connection = .connecting
    }

    func completeReconnect() {
        guard !isInBackground else { return }
        connection = .connected
    }

    @discardableResult
    func startRun() -> UUID? {
        guard connection == .connected, !isInBackground,
              run == .idle || run == .stopped else { return nil }
        let id = UUID()
        runID = id
        run = .running
        stopRequestAccepted = false
        return id
    }

    /// The local stop intent is distinct from the host's acknowledgement.
    @discardableResult
    func requestStop() -> Bool {
        guard connection == .connected, !isInBackground, run == .running else { return false }
        run = .stopRequested
        return true
    }

    @discardableResult
    func acknowledgeStopRequest(id: UUID) -> Bool {
        guard runID == id, run == .stopRequested, !stopRequestAccepted else { return false }
        stopRequestAccepted = true
        return true
    }

    @discardableResult
    func finishRun(id: UUID) -> Bool {
        guard runID == id, run == .running || run == .stopRequested else { return false }
        run = .stopped
        return true
    }

    /// A transient presentation conflict does not own or consume the request.
    /// This small recipe allows one unresolved request; queuing belongs to a host.
    @discardableResult
    func receiveAuthorization(id: UUID, context: String) -> Bool {
        guard !finishedAuthorizationIDs.contains(id),
              authorization?.isUnresolved != true else { return false }
        authorization = Authorization(id: id, context: context, status: .pending, decision: nil, decisionID: nil)
        return true
    }

    @discardableResult
    func decideAuthorization(id: UUID, decision: AuthorizationDecision) -> Bool {
        guard connection == .connected, !isInBackground,
              var request = authorization, request.id == id, request.status == .pending else { return false }
        request.decision = decision
        request.decisionID = UUID()
        request.status = .decisionPending
        authorization = request
        return true
    }

    /// A decision remains pending through reconnect; the transport reconciles it.
    /// Rejection here means the decision was not accepted, not a denied permission.
    @discardableResult
    func resolveAuthorization(id: UUID, decisionID: UUID, accepted: Bool) -> Bool {
        guard var request = authorization, request.id == id,
              request.decisionID == decisionID,
              request.status == .decisionPending, let decision = request.decision else { return false }
        if accepted {
            request.status = decision == .allowOnce ? .allowedOnce : .denied
            finishedAuthorizationIDs.insert(id)
        } else {
            request.status = .pending
            request.decision = nil
            request.decisionID = nil
        }
        authorization = request
        return true
    }

    @discardableResult
    func withdrawAuthorization(id: UUID) -> Bool {
        guard var request = authorization, request.id == id, request.isUnresolved else { return false }
        request.status = .withdrawn
        request.decision = nil
        request.decisionID = nil
        finishedAuthorizationIDs.insert(id)
        authorization = request
        return true
    }
}
