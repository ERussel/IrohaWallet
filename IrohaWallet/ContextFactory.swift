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

        let operationFactory = NetworkOperationFactory(account: account)
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

        try module
            .inserting(viewModelFactory: { headerViewModel }, at: 0)
            .with(cellNib: headerNib, for: headerViewModel.cellReuseIdentifier)
    }

    private static func configureHistory(module: HistoryModuleBuilderProtocol) {
        module
            .with(emptyStateDataSource: DefaultEmptyStateDataSource.history)
            .with(supportsFilter: false)
    }

    private static func configureContacts(module: ContactsModuleBuilderProtocol) {
        module
            .with(searchPlaceholder: "Enter public key")
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
