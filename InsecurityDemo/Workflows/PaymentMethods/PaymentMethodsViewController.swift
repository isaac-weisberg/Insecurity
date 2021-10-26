import UIKit

class PaymentMethodsViewController: UIViewController, UITableViewDataSource {
    var onDone: ((PaymentMethodsScreenResult) -> Void)?
    var onNewPaymentMethodRequested: (() -> Void)?
    
    let tableView = UITableView(frame: .zero, style: .plain)
    
    var paymentMethods: [PaymentMethod] = [
        PaymentMethod(cardNumber: "1234 1234 1234 1234", name: "MIKE OXLONG"),
        PaymentMethod(cardNumber: "4321 4321 4321 4321", name: "JEREMY ELBERTSON")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let rightBarButton = NavigationBarButton(barButtonSystemItem: .add, target: nil, action: nil)
        navigationItem.rightBarButtonItem = rightBarButton
        rightBarButton.onTap = { [weak self] in
            self?.onNewPaymentMethodRequested?()
        }
        navigationItem.title = "Cards"
        navigationItem.largeTitleDisplayMode = .automatic
        view.backgroundColor = .systemBackgroundCompat
        
        tableView.dataSource = self
        tableView.register(PaymentMethodTableCell.self)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        navigationController?.navigationBar.sizeToFit()
    }
    
    func handleNewPaymentMethodAdded(_ paymentMethod: PaymentMethod) {
        paymentMethods.append(paymentMethod)
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return paymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(PaymentMethodTableCell.self, for: indexPath)
        
        let paymentMethod = paymentMethods[indexPath.row]
        
        cell.apply(paymentMethod)
        
        return cell
    }
}
