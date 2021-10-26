import UIKit
import SnapKit

class PaymentMethodTableCell: UITableViewCell {
    let paymentMethodLogo = AutoscaleImageView()
    let cardNumberLabel = UILabel()
    let nameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(paymentMethodLogo)
        paymentMethodLogo.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(20)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }
        
        cardNumberLabel.setContentHuggingPriority(.required, for: .vertical)
        cardNumberLabel.textColor = .labelCompat
        cardNumberLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentView.addSubview(cardNumberLabel)
        cardNumberLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(paymentMethodLogo.snp.right).offset(16)
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().inset(16)
        }
        
        nameLabel.setContentHuggingPriority(.required, for: .vertical)
        nameLabel.textColor = .systemGray
        nameLabel.font = .systemFont(ofSize: 13, weight: .light)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(paymentMethodLogo.snp.right).offset(16)
            make.top.equalTo(cardNumberLabel.snp.bottom).offset(8)
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func apply(_ model: PaymentMethod) {
        paymentMethodLogo.image = UIImage(named: "old-visa-logo")
        cardNumberLabel.text = model.cardNumber
        nameLabel.text = model.name
    }
}
