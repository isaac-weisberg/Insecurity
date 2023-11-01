import Foundation
import UIKit

class ProfileOrdersButton: UIView {
    var onTap: (() -> Void)?
    
    let contentView = UIView()
    let titleLabel = UILabel()
    let arrowLabel = UILabel()
    
    init(_ name: String, _ bgColor: UIColor) {
        super.init(frame: .zero)
        
        contentView.backgroundColor = bgColor
        contentView.layer.cornerRadius = 16
        contentView.layer.shadowRadius = 16
        contentView.layer.shadowOpacity = 0.25
        contentView.layer.shadowColor = UIColor.black.cgColor
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
            make.height.equalTo(86)
        }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contentViewTap))
        contentView.addGestureRecognizer(tapGestureRecognizer)
        
        titleLabel.text = name
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.leading.equalToSuperview().inset(16)
        }
        
        arrowLabel.text = ">"
        arrowLabel.font = .systemFont(ofSize: 22, weight: .light)
        contentView.addSubview(arrowLabel)
        arrowLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(titleLabel.snp.trailing).offset(16)
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func contentViewTap() {
        onTap?()
    }
}
