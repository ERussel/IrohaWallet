import Foundation
import RobinHood
import IrohaCommunication
import CommonWallet

final class TransferOperation: BaseOperation<Void> {
    let service: IRNetworkService
    let transferInfo: TransferInfo
    let userSigner: IRSignatureCreatorProtocol
    let userPublicKey: IRPublicKeyProtocol

    init(service: IRNetworkService,
         transferInfo: TransferInfo,
         userSigner: IRSignatureCreatorProtocol,
         userPublicKey: IRPublicKeyProtocol) {
        self.service = service
        self.transferInfo = transferInfo
        self.userSigner = userSigner
        self.userPublicKey = userPublicKey
    }

    override func main() {
        super.main()

        if result != nil {
            return
        }

        if isCancelled {
            return
        }

        // TODO: Add Transfer logic here
    }
}
