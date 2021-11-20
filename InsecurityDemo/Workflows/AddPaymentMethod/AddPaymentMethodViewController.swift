import UIKit

class AddPaymentMethodViewController: UIViewController {
    var onPaymentMethodAdded: ((PaymentMethod) -> Void)?
    
    let titleLabel = UILabel()
    let cardNumberField = CardNumberTextField()
    let separator1 = SeparatorView()
    let cardholderField = CardHolderTextField()
    let cvvField = CVVTextField()
    let separator2 = SeparatorView()
    let button = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackgroundCompat
        
        titleLabel.text = "Add Card"
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 32, weight: .semibold)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        
        view.addSubview(cardNumberField)
        cardNumberField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
        }
        
        view.addSubview(separator1)
        separator1.snp.makeConstraints { make in
            make.top.equalTo(cardNumberField.snp.bottom).offset(8)
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        view.addSubview(cardholderField)
        cardholderField.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom).offset(12)
            make.leading.equalToSuperview()
        }
        
        view.addSubview(cvvField)
        cvvField.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom).offset(12)
            make.leading.equalTo(cardholderField.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.width.equalTo(160)
        }
        
        view.addSubview(separator2)
        separator2.snp.makeConstraints { make in
            make.top.equalTo(cvvField.snp.bottom).offset(8)
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        button.setTitle("Submit", for: .normal)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(separator2.snp.bottom).offset(16)
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.centerX.equalToSuperview()
        }
        button.addTarget(self, action: #selector(submitTap), for: .touchUpInside)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(outsideTap))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func outsideTap() {
        view.endEditing(true)
    }
    
    @objc func submitTap() {
        let cardNumber = (cardNumberField.text ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cardHolderName = (cardholderField.text ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.onPaymentMethodAdded?(PaymentMethod(cardNumber: cardNumber, name: cardHolderName))
    }
}
