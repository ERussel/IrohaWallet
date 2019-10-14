/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet
import RobinHood
import IrohaCommunication

enum NetworkOperationFactoryError: Error {
    case undefined
}

final class NetworkOperationFactory {
    let account: WalletAccountSettingsProtocol
    let irohaService: IRNetworkService

    let registrationSigner: IRSignatureCreatorProtocol
    let registrationAccountId: IRAccountId
    let registrationPublicKey: IRPublicKeyProtocol

    init(account: WalletAccountSettingsProtocol) throws {
        self.account = account

        let address = try IRAddressFactory.address(withIp: "188.166.164.96", port: "50051")
        irohaService = IRNetworkService(address: address)

        let privateKeyData = NSData(hexString: "7e00405ece477bb6dd9b03a78eee4e708afc2f5bcdce399573a5958942f4a390")! as Data
        let privateKey = IREd25519PrivateKey(rawData: privateKeyData)!
        let keypair = IREd25519KeyFactory().derive(fromPrivateKey: privateKey)!

        registrationSigner = IREd25519Sha512Signer(privateKey: privateKey)!
        registrationAccountId = try IRAccountIdFactory.accountId(withName: "registrator", domain: account.accountId.domain)
        registrationPublicKey = keypair.publicKey()
    }
}

extension NetworkOperationFactory: WalletNetworkOperationFactoryProtocol {
    func fetchBalanceOperation(_ assets: [IRAssetId]) -> BaseOperation<[BalanceData]?> {
        return AccountOperation(service: irohaService,
                                userAccountId: account.accountId,
                                userSigner: account.signer,
                                userPublicKey: account.publicKey,
                                assetIds: assets,
                                registrationAccountId: registrationAccountId,
                                registrationSigner: registrationSigner,
                                registrationPublicKey: registrationPublicKey)
    }

    func fetchTransactionHistoryOperation(_ filter: WalletHistoryRequest, pagination: OffsetPagination) -> BaseOperation<AssetTransactionPageData?> {
        return ClosureOperation {
            return AssetTransactionPageData(transactions: [])
        }
    }

    func transferMetadataOperation(_ assetId: IRAssetId) -> BaseOperation<TransferMetaData?> {
        return ClosureOperation {
            return nil
        }
    }

    func transferOperation(_ info: TransferInfo) -> BaseOperation<Void> {
        return ClosureOperation {}
    }

    func searchOperation(_ searchString: String) -> BaseOperation<[SearchData]?> {
        return ClosureOperation { return [] }
    }

    func contactsOperation() -> BaseOperation<[SearchData]?> {
        return ClosureOperation { return [] }
    }

    func withdrawalMetadataOperation(_ info: WithdrawMetadataInfo) -> BaseOperation<WithdrawMetaData?> {
        return ClosureOperation { return nil }
    }

    func withdrawOperation(_ info: WithdrawInfo) -> BaseOperation<Void> {
        return ClosureOperation {}
    }


}
