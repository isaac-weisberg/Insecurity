import Insecurity
import UIKit

class ProfileViewController: UIViewController {
    var onPaymentMethodsRequested: (() -> Void)?
    
    let scrollView = UIScrollView()
    let scrollContentView = UIView()
    let iconView = UIImageView(frame: .zero)
    let nameLabel = UILabel()
    let ageLabel = UILabel()
    let verticalStack = UIStackView()
    let paymentMethodsView = ProfileOrdersButton("Payment Methods", .systemYellow.withAlphaComponent(0.5))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Profile"
        
        view.backgroundColor = .systemBackgroundCompat
        
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.addSubview(scrollContentView)
        scrollContentView.snp.makeConstraints { make in
            make.width.edges.equalToSuperview()
        }
        
        let iconHeight: CGFloat = 92
        iconView.image = UIImage(named: "dudu")
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = iconHeight * 0.5
        scrollContentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.height.width.equalTo(iconHeight)
        }
        
        nameLabel.text = "Mace Dudu"
        nameLabel.font = .systemFont(ofSize: 32, weight: .semibold)
        scrollContentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView)
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
        }
        
        ageLabel.text = "AGE 42"
        ageLabel.font = .systemFont(ofSize: 24, weight: .light)
        ageLabel.textColor = .systemYellow
        scrollContentView.addSubview(ageLabel)
        ageLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalTo(iconView)
        }
        
        verticalStack.axis = .vertical
        scrollContentView.addSubview(verticalStack)
        verticalStack.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        verticalStack.addArrangedSubview(ProfileOrdersButton("Orders", .systemYellow.withAlphaComponent(1)))
        verticalStack.addArrangedSubview(paymentMethodsView)
        verticalStack.addArrangedSubview(ProfileOrdersButton("Settings", .systemYellow.withAlphaComponent(0.2)))
        
        paymentMethodsView.onTap = { [weak self] in
            self?.onPaymentMethodsRequested?()
        }
        
//        DispatchQueue.main.asyncAfter(0.25) { [weak self] in
//            guard let self = self else { return }
            
//            self.onPaymentMethodsRequested?()
//            self.startPaymentMethodScreen()
//            self.startPaymentMethodScreenNavigation()
//            self.startPaymentMethodScreenWithNewNavigation()
//        }
    }
    
    func handleDefaultPaymentMethodChanged() {
        
    }
}
