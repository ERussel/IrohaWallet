import UIKit
import CommonWallet

final class WalletHeaderCell: UICollectionViewCell {
    @IBOutlet private var titleLabel: UILabel!

    private(set) var headerViewModel: WalletHeaderViewModelProtocol?

    override func prepareForReuse() {
        super.prepareForReuse()

        headerViewModel = nil
    }
}

extension WalletHeaderCell: WalletViewProtocol {
    var viewModel: WalletViewModelProtocol? {
        return headerViewModel
    }

    func bind(viewModel: WalletViewModelProtocol) {
        if let headerViewModel = viewModel as? WalletHeaderViewModelProtocol {
            self.headerViewModel = headerViewModel

            titleLabel.text = headerViewModel.title
            titleLabel.textColor = headerViewModel.style.color
            titleLabel.font = headerViewModel.style.font
        }
    }
}
