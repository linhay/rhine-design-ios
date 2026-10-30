import XCTest
@testable import RhineExample

@MainActor
final class AgentSessionModelTests: XCTestCase {
    func testUnknownDeliveryKeepsDraftAndBlocksAutomaticOrManualResend() throws {
        let model = AgentSessionModel()
        model.draft = "合成问题，保留完整草稿"
        let attempt = try XCTUnwrap(model.requestSend())
        XCTAssertNil(model.requestSend())
        model.disconnect()
        XCTAssertEqual(model.send, .unknown)
        XCTAssertEqual(model.draft, attempt.text)
        model.enterForeground()
        XCTAssertEqual(model.connection, .connecting)
        model.completeReconnect()
        XCTAssertEqual(model.connection, .connected)
        XCTAssertNil(model.requestSend(), "Reconnection does not authorize resending an unknown attempt")
        XCTAssertEqual(model.submission, attempt)
        XCTAssertEqual(model.resolveSend(id: attempt.id, accepted: true), attempt.text)
        XCTAssertEqual(model.draft, "")
        XCTAssertNil(model.resolveSend(id: attempt.id, accepted: true), "Duplicate acknowledgements do not append twice")
    }

    func testLateSendAcceptanceDoesNotEraseReplacementOrRecreatedDraft() throws {
        let model = AgentSessionModel()
        model.draft = "第一份合成草稿"
        let first = try XCTUnwrap(model.requestSend())
        model.draft = "下一份合成草稿"
        XCTAssertEqual(model.resolveSend(id: first.id, accepted: true), first.text)
        XCTAssertEqual(model.draft, "下一份合成草稿")
        let second = try XCTUnwrap(model.requestSend())
        model.draft = "临时编辑"
        model.draft = second.text
        XCTAssertEqual(model.resolveSend(id: second.id, accepted: true), second.text)
        XCTAssertEqual(model.draft, second.text, "Text equality alone cannot establish draft ownership")
        XCTAssertNil(model.resolveSend(id: first.id, accepted: true))
        XCTAssertEqual(model.draft, second.text)
    }

    func testExplicitRejectionPreservesDraftAndRetryGetsNewIdentity() throws {
        let model = AgentSessionModel()
        model.draft = "  合成内容不自动修剪  "
        let first = try XCTUnwrap(model.requestSend())
        XCTAssertEqual(first.text, model.draft)
        XCTAssertNil(model.resolveSend(id: UUID(), accepted: true))
        XCTAssertEqual(model.send, .awaitingAcceptance)
        model.resolveSend(id: first.id, accepted: false)
        XCTAssertEqual(model.send, .rejected)
        XCTAssertEqual(model.draft, first.text)
        let retry = try XCTUnwrap(model.requestSend())
        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertEqual(retry.text, first.text)
        model.resolveSend(id: first.id, accepted: true)
        XCTAssertEqual(model.send, .awaitingAcceptance)
        XCTAssertEqual(model.draft, first.text)
    }

    func testBackgroundReconnectPreservesRunDraftAndUnresolvedDecisions() throws {
        let model = AgentSessionModel()
        let runID = try XCTUnwrap(model.startRun())
        model.draft = "后台前的合成草稿"
        let requestID = UUID()
        XCTAssertTrue(model.receiveAuthorization(id: requestID, context: "读取合成文件"))
        XCTAssertTrue(model.decideAuthorization(id: requestID, decision: .allowOnce))
        model.enterBackground()
        XCTAssertEqual(model.connection, .offline)
        XCTAssertEqual(model.run, .running)
        XCTAssertEqual(model.runID, runID)
        XCTAssertEqual(model.draft, "后台前的合成草稿")
        XCTAssertEqual(model.authorization?.status, .decisionPending)
        model.completeReconnect()
        XCTAssertEqual(model.connection, .offline)
        model.enterForeground()
        XCTAssertEqual(model.connection, .connecting)
        XCTAssertNil(model.requestSend())
        XCTAssertFalse(model.requestStop())
        model.completeReconnect()
        XCTAssertEqual(model.run, .running)
        XCTAssertEqual(model.authorization?.status, .decisionPending)
        XCTAssertFalse(model.decideAuthorization(id: requestID, decision: .allowOnce))
    }

    func testStopIntentAcceptanceAndCompletionAreSeparate() throws {
        let model = AgentSessionModel()
        let first = try XCTUnwrap(model.startRun())
        XCTAssertTrue(model.requestStop())
        XCTAssertEqual(model.run, .stopRequested)
        XCTAssertFalse(model.stopRequestAccepted)
        XCTAssertFalse(model.requestStop())
        XCTAssertFalse(model.acknowledgeStopRequest(id: UUID()))
        XCTAssertTrue(model.acknowledgeStopRequest(id: first))
        XCTAssertEqual(model.run, .stopRequested, "Accepted stop request does not mean the remote run has stopped")
        XCTAssertTrue(model.stopRequestAccepted)
        model.disconnect()
        XCTAssertEqual(model.run, .stopRequested)
        XCTAssertTrue(model.finishRun(id: first))
        XCTAssertEqual(model.run, .stopped)
        model.enterForeground()
        model.completeReconnect()
        let second = try XCTUnwrap(model.startRun())
        XCTAssertNotEqual(first, second)
        XCTAssertFalse(model.stopRequestAccepted)
        XCTAssertFalse(model.finishRun(id: first), "A stale completion must not stop a new run")
        XCTAssertEqual(model.run, .running)
    }

    func testAuthorizationCannotBeOverwrittenAndRequiresDecisionConfirmation() {
        let model = AgentSessionModel()
        let first = UUID()
        XCTAssertTrue(model.receiveAuthorization(id: first, context: "仅本次读取 synthetic.txt"))
        XCTAssertFalse(model.receiveAuthorization(id: UUID(), context: "另一个请求"))
        XCTAssertFalse(model.receiveAuthorization(id: first, context: "不能替换上下文"))
        XCTAssertEqual(model.authorization?.context, "仅本次读取 synthetic.txt")
        XCTAssertFalse(model.resolveAuthorization(id: first, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        XCTAssertTrue(model.decideAuthorization(id: first, decision: .allowOnce))
        XCTAssertEqual(model.authorization?.status, .decisionPending)
        XCTAssertFalse(model.decideAuthorization(id: first, decision: .deny))
        XCTAssertTrue(model.resolveAuthorization(id: first, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        XCTAssertEqual(model.authorization?.status, .allowedOnce)
        XCTAssertFalse(model.receiveAuthorization(id: first, context: "不能重复同一授权"))
        XCTAssertFalse(model.resolveAuthorization(id: first, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        let second = UUID()
        XCTAssertTrue(model.receiveAuthorization(id: second, context: "第二次合成请求"))
        XCTAssertFalse(model.resolveAuthorization(id: first, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        XCTAssertEqual(model.authorization?.id, second)
        XCTAssertTrue(model.decideAuthorization(id: second, decision: .deny))
        XCTAssertTrue(model.resolveAuthorization(id: second, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        XCTAssertEqual(model.authorization?.status, .denied)
    }

    func testWithdrawalWinsOverLateDecisionAndCannotBeResurrected() {
        let model = AgentSessionModel()
        let request = UUID()
        model.receiveAuthorization(id: request, context: "合成请求")
        model.decideAuthorization(id: request, decision: .allowOnce)
        XCTAssertTrue(model.withdrawAuthorization(id: request))
        XCTAssertEqual(model.authorization?.status, .withdrawn)
        XCTAssertNil(model.authorization?.decision)
        XCTAssertFalse(model.resolveAuthorization(id: request, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        XCTAssertFalse(model.decideAuthorization(id: request, decision: .allowOnce))
        XCTAssertFalse(model.receiveAuthorization(id: request, context: "撤回后重放"))
        let replacement = UUID()
        XCTAssertTrue(model.receiveAuthorization(id: replacement, context: "新请求"))
        XCTAssertFalse(model.withdrawAuthorization(id: request))
        XCTAssertEqual(model.authorization?.id, replacement)
        XCTAssertEqual(model.authorization?.status, .pending)
    }

    func testDecisionFailureNeedsExplicitNewChoiceAndOfflineCannotDecide() throws {
        let model = AgentSessionModel()
        let request = UUID()
        model.receiveAuthorization(id: request, context: "合成请求")
        model.disconnect()
        XCTAssertFalse(model.decideAuthorization(id: request, decision: .allowOnce))
        XCTAssertEqual(model.authorization?.status, .pending)
        model.enterForeground()
        model.completeReconnect()
        XCTAssertTrue(model.decideAuthorization(id: request, decision: .allowOnce))
        let failedDecision = try XCTUnwrap(model.authorization?.decisionID)
        XCTAssertTrue(model.resolveAuthorization(id: request, decisionID: failedDecision, accepted: false))
        XCTAssertEqual(model.authorization?.status, .pending)
        XCTAssertNil(model.authorization?.decision)
        XCTAssertFalse(model.resolveAuthorization(id: request, decisionID: model.authorization?.decisionID ?? UUID(), accepted: true))
        XCTAssertTrue(model.decideAuthorization(id: request, decision: .deny))
        let currentDecision = try XCTUnwrap(model.authorization?.decisionID)
        XCTAssertNotEqual(failedDecision, currentDecision)
        XCTAssertFalse(model.resolveAuthorization(id: request, decisionID: failedDecision, accepted: true),
                       "A stale acknowledgement of the old allow choice cannot complete the new deny choice")
        XCTAssertEqual(model.authorization?.status, .decisionPending)
        XCTAssertTrue(model.resolveAuthorization(id: request, decisionID: currentDecision, accepted: true))
        XCTAssertEqual(model.authorization?.status, .denied)
    }
}
