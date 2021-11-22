import UIKit

class PaymentMethodAddCell: UITableViewCell {
    var onTap: (() -> Void)?
    
    let button = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func setup() {
        button.setTitle("Add Payment Method", for: .normal)
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(16)
        }
        button.addTarget(self, action: #selector(buttonTap), for: .touchUpInside)
    }
    
    @objc func buttonTap() {
        onTap?()
    }
}
