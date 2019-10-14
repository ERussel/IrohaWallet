import Foundation
import RobinHood
import IrohaCommunication
import CommonWallet

final class AccountOperation: BaseOperation<[BalanceData]?> {
    let service: IRNetworkService
    let assetIds: [IRAssetId]
    let userSigner: IRSignatureCreatorProtocol
    let userAccountId: IRAccountId
    let userPublicKey: IRPublicKeyProtocol
    let registrationSigner: IRSignatureCreatorProtocol
    let registrationAccountId: IRAccountId
    let registrationPublicKey: IRPublicKeyProtocol

    init(service: IRNetworkService,
         userAccountId: IRAccountId,
         userSigner: IRSignatureCreatorProtocol,
         userPublicKey: IRPublicKeyProtocol,
         assetIds: [IRAssetId],
         registrationAccountId: IRAccountId,
         registrationSigner: IRSignatureCreatorProtocol,
         registrationPublicKey: IRPublicKeyProtocol) {
        self.service = service
        self.userAccountId = userAccountId
        self.userSigner = userSigner
        self.userPublicKey = userPublicKey
        self.assetIds = assetIds
        self.registrationAccountId = registrationAccountId
        self.registrationSigner = registrationSigner
        self.registrationPublicKey = registrationPublicKey
    }

    override func main() {
        super.main()

        if result != nil {
            return
        }

        if isCancelled {
            return
        }

        let semaphore = DispatchSemaphore(value: 0)

        var resultData: Any?

        _ = performAccountQuery().onThen({ result -> IRPromise? in
            return self.handleQuery(result: result)
        }).onThen({ result -> IRPromise? in
            defer {
                semaphore.signal()
            }

            resultData = result

            return nil
        }).onError({ result -> IRPromise? in
            defer {
                semaphore.signal()
            }

            resultData = result

            return nil
        })

        semaphore.wait()

        if isCancelled {
            return
        }

        if let error = resultData as? Error {
            print("Balance fetching failed: \(error)")

            result = .failure(error)
            return
        }

        print("Balances were successfull fetched")

        if let balances = resultData as? [BalanceData] {
            result = .success(balances)
        } else {
            let defaultBalances = createDefaultResult()
            result = .success(defaultBalances)
        }
    }

    private func handleQuery(result: Any?) -> IRPromise {
        if let balanceResponse = result as? IRAccountAssetsResponse {
            let balances = createResult(from: balanceResponse)
            return IRPromise(result: balances)
        }

        if let errorResponse = result as? IRErrorResponse {
            if errorResponse.reason == .statefulInvalid, errorResponse.code == 3 {
                print("No account exists, creating new one...")
                return createAccount()
            } else {
                print("Did receive error on balance fetch: \(errorResponse.message) (code: \(errorResponse.code))")
                let error = NSError.error(message: errorResponse.message)
                return IRPromise(result: error)
            }
        }

        print("Did receive undefined balance response.")

        let error = NSError.error(message: "Undefined balance query response")
        return IRPromise(result: error)
    }

    private func performAccountQuery() -> IRPromise {
        do {
            let query = try IRQueryBuilder(creatorAccountId: userAccountId)
                .getAccountAssets(userAccountId, pagination: nil)
                .build()
                .signed(withSignatory: userSigner, signatoryPublicKey: userPublicKey)

            return service.execute(query)
        } catch {
            return IRPromise(result: error as NSError)
        }
    }

    private func createAccount() -> IRPromise {
        do {
            let request = try IRTransactionBuilder(creatorAccountId: registrationAccountId)
                .createAccount(userAccountId, publicKey: userPublicKey)
                .build()
                .signed(withSignatories: [registrationSigner], signatoryPublicKeys: [registrationPublicKey])

            return service.execute(request)
                .onThen({ result -> IRPromise? in
                    if let sentTransactionHash = result as? Data {
                        print("Account creation transaction has been sent \((sentTransactionHash as NSData).toHexString())")
                        return IRRepeatableStatusStream.onTransactionStatus(.committed,
                                                                            withHash: sentTransactionHash,
                                                                            from: self.service);
                    } else {
                        return IRPromise(result: result)
                    }
                })
        } catch {
            return IRPromise(result: error as NSError)
        }
    }

    private func createDefaultResult() -> [BalanceData] {
        return assetIds.map { BalanceData(identifier: $0.identifier(), balance: "0") }
    }

    private func createResult(from balanceResponse: IRAccountAssetsResponse) -> [BalanceData] {
        return assetIds.map { assetId in
            let accountAssets = balanceResponse.accountAssets
            if let accountAsset = accountAssets.first(where: { $0.assetId.identifier() == assetId.identifier() }) {
                return BalanceData(identifier: assetId.identifier(), balance: accountAsset.balance.value)
            } else {
                return BalanceData(identifier: assetId.identifier(), balance: "0")
            }
        }
    }
}
