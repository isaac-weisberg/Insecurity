import UIKit
import SnapKit

class CurrencySelectionViewController: UIViewController {
    var onCurrencySelected: ((CurrencySelection) -> Void)?
    
    let titleLabel = UILabel()
    let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        titleLabel.numberOfLines = 0
        titleLabel.text = "Select currency"
        titleLabel.font = .systemFont(ofSize: 40, weight: .semibold)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }
        
        ["USD", "RUB", "EUR", "ZWD"].forEach { currency in
            let currencyView = CurrencyView(currency: currency)
            
            currencyView.onSelected = { [weak self] in
                self?.onCurrencySelected?(CurrencySelection(currencyCode: currency))
            }
            
            stackView.addArrangedSubview(currencyView)
        }
    }
}
