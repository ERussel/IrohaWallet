/**
* Copyright Soramitsu Co., Ltd. All Rights Reserved.
* SPDX-License-Identifier: GPL-3.0
*/

import Foundation
import CommonWallet
import SoraKeystore
import IrohaCrypto
import IrohaCommunication

enum ContextFactoryError: Error {
    case keypairCreationFailure
    case signerCreationFailure
}

struct ContextFactory {

    static func createContext() throws -> CommonWalletContextProtocol {
        let account = try createAccountSettings()

        let operationFactory = try NetworkOperationFactory(account: account)
        let contextBuilder = CommonWalletBuilder.builder(with: account, networkOperationFactory: operationFactory)

        try configureAccountList(module: contextBuilder.accountListModuleBuilder)
        configureHistory(module: contextBuilder.historyModuleBuilder)
        configureContacts(module: contextBuilder.contactsModuleBuilder)

        return try contextBuilder.build()
    }

    private static func configureAccountList(module: AccountListModuleBuilderProtocol) throws {
        let titleFont = UIFont(name: "HelveticaNeue-Bold", size: 16.0)!
        let titleStyle = WalletTextStyle(font: titleFont, color: .black)
        let headerViewModel = WalletHeaderViewModel(title: "Wallet", style: titleStyle)
        let headerNib = UINib(nibName: "WalletHeaderCell", bundle: Bundle.main)

        let shadow = WalletShadowStyle(offset: CGSize(width: 0.0, height: 5.0),
                                       color: UIColor.black,
                                       opacity: 0.04,
                                       blurRadius: 4.0)

        let cardStyle = CardAssetStyle(backgroundColor: .white,
                                       leftFillColor: UIColor(red: 75.0 / 255.0, green: 140.0 / 255.0, blue: 189.0 / 255.0, alpha: 1.0),
                                       symbol: WalletTextStyle(font: UIFont(name: "HelveticaNeue-Medium", size: 18.0)!, color: .white),
                                       title: WalletTextStyle(font: UIFont(name: "HelveticaNeue-Medium", size: 18.0)!, color: UIColor.black),
                                       subtitle: WalletTextStyle(font: UIFont(name: "HelveticaNeue", size: 14.0)!,
                                                                 color: UIColor(white: 97.0 / 255.0, alpha: 1.0)),
                                       accessory: WalletTextStyle(font: UIFont(name: "HelveticaNeue", size: 14.0)!,
                                                                  color: UIColor(white: 97.0 / 255.0, alpha: 1.0)),
                                       shadow: shadow,
                                       cornerRadius: 10.0)

        try module
            .inserting(viewModelFactory: { headerViewModel }, at: 0)
            .with(cellNib: headerNib, for: headerViewModel.cellReuseIdentifier)
            .with(assetCellStyle: AssetCellStyle.card(cardStyle))
    }

    private static func configureHistory(module: HistoryModuleBuilderProtocol) {
        module
            .with(emptyStateDataSource: DefaultEmptyStateDataSource.history)
            .with(supportsFilter: false)
    }

    private static func configureContacts(module: ContactsModuleBuilderProtocol) {
        module
            .with(searchPlaceholder: "Enter account id")
            .with(contactsEmptyStateDataSource: DefaultEmptyStateDataSource.contacts)
            .with(searchEmptyStateDataSource: DefaultEmptyStateDataSource.search)
            .with(supportsLiveSearch: false)
    }

    private static func createAccountSettings() throws -> WalletAccountSettingsProtocol {
        let keypair = try retrieveKeypair()

        guard let signer = IREd25519Sha512Signer(privateKey: keypair.privateKey()) else {
            throw ContextFactoryError.signerCreationFailure
        }

        let accountId = try createAccountId(from: keypair.publicKey())
        let asset = try createAsset()

        return WalletAccountSettings(accountId: accountId,
                                     assets: [asset],
                                     signer: signer,
                                     publicKey: keypair.publicKey())
    }

    private static func retrieveKeypair() throws -> IRCryptoKeypairProtocol {
        let keychainKey = "privateKey"
        let keypairFactory = IREd25519KeyFactory()
        let keychain = Keychain()

        if let privateKeyData = try? keychain.fetchKey(for: keychainKey),
            let privateKey = IREd25519PrivateKey(rawData: privateKeyData),
            let keypair = keypairFactory.derive(fromPrivateKey: privateKey) {

            return keypair
        }

        guard let keypair = keypairFactory.createRandomKeypair() else {
            throw ContextFactoryError.keypairCreationFailure
        }

        try keychain.saveKey(keypair.privateKey().rawData(), with: keychainKey)
        return keypair
    }

    private static func createAccountId(from publicKey: IRPublicKeyProtocol) throws -> IRAccountId {
        let domain = try createDomain()
        let publicKeyData = publicKey.rawData() as NSData
        let accountName = String(publicKeyData.toHexString().prefix(32))
        return try IRAccountIdFactory.accountId(withName: accountName, domain: domain)
    }

    private static func createAsset() throws -> WalletAsset {
        let domain = try createDomain()
        let assetId = try IRAssetIdFactory.assetId(withName: "bc", domain: domain)

        return WalletAsset(identifier: assetId, symbol: "β", details: "Bootcamp Token")
    }

    private static func createDomain() throws -> IRDomain {
        return try IRDomainFactory.domain(withIdentitifer: "bootcamp")
    }
}
