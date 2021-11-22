import UIKit

class AddPaymentMethodViewController: UIViewController {
    var onPaymentMethodAdded: ((PaymentMethod) -> Void)?
    
    let scrollView = UIScrollView()
    let scrollContentView = UIView()
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
        
        navigationItem.largeTitleDisplayMode = .never
        
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints { make in
            make.width.edges.equalToSuperview()
        }
        
        titleLabel.text = "Add Card"
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 32, weight: .semibold)
        scrollContentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(scrollContentView.snp.top).offset(8)
            make.left.right.equalToSuperview().inset(16)
        }
        
        scrollContentView.addSubview(cardNumberField)
        cardNumberField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
        }
        
        scrollContentView.addSubview(separator1)
        separator1.snp.makeConstraints { make in
            make.top.equalTo(cardNumberField.snp.bottom).offset(8)
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        scrollContentView.addSubview(cardholderField)
        cardholderField.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom).offset(12)
            make.leading.equalToSuperview()
        }
        
        scrollContentView.addSubview(cvvField)
        cvvField.snp.makeConstraints { make in
            make.top.equalTo(separator1.snp.bottom).offset(12)
            make.leading.equalTo(cardholderField.snp.trailing).offset(16)
            make.trailing.equalToSuperview()
            make.width.equalTo(160)
        }
        
        scrollContentView.addSubview(separator2)
        separator2.snp.makeConstraints { make in
            make.top.equalTo(cvvField.snp.bottom).offset(8)
            make.height.equalTo(1)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        button.setTitle("Submit", for: .normal)
        scrollContentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalTo(separator2.snp.bottom).offset(16)
            make.leading.greaterThanOrEqualToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-16)
        }
        button.addTarget(self, action: #selector(submitTap), for: .touchUpInside)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(outsideTap))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func outsideTap() {
        scrollContentView.endEditing(true)
    }
    
    @objc func submitTap() {
        let cardNumber = (cardNumberField.text ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let cardHolderName = (cardholderField.text ?? "").uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.onPaymentMethodAdded?(PaymentMethod(cardNumber: cardNumber, name: cardHolderName))
    }
}
