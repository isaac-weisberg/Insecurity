import UIKit

class CurrencyView: UIView {
    var onSelected: (() -> Void)?
    
    let container = UIView()
    let currencyNameLabel = UILabel()
    
    init(currency: String) {
        super.init(frame: .zero)
        
        container.layer.cornerRadius = 16
        container.layer.shadowOffset = CGSize(width: 0, height: 2)
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowRadius = 16
        container.backgroundColor = .systemBackgroundCompat
        addSubview(container)
        container.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        container.addGestureRecognizer(gestureRecognizer)
        
        currencyNameLabel.text = currency
        container.addSubview(currencyNameLabel)
        currencyNameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tap() {
        onSelected?()
    }
}
