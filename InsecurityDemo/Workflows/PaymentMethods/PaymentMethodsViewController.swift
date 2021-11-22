import UIKit

class PaymentMethodsViewController: UIViewController, UITableViewDataSource {
    var onDone: ((PaymentMethodsScreenResult) -> Void)?
    var onNewPaymentMethodRequested: (() -> Void)?
    
    let tableView = UITableView(frame: .zero, style: .plain)
    
    enum Cell {
        case paymentMethod(PaymentMethod)
        case addButton
    }
    
    var cells: [Cell]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if navigationController == nil {
            cells = [
                .paymentMethod(PaymentMethod(cardNumber: "1234 1234 1234 1234", name: "MIKE OXLONG")),
                .paymentMethod(PaymentMethod(cardNumber: "4321 4321 4321 4321", name: "JEREMY ELBERTSON")),
                .addButton
            ]
        } else {
            cells = [
                .paymentMethod(PaymentMethod(cardNumber: "1234 1234 1234 1234", name: "MIKE OXLONG")),
                .paymentMethod(PaymentMethod(cardNumber: "4321 4321 4321 4321", name: "JEREMY ELBERTSON"))
            ]
        }
        
        let rightBarButton = NavigationBarButton(barButtonSystemItem: .add, target: nil, action: nil)
        navigationItem.rightBarButtonItem = rightBarButton
        rightBarButton.onTap = { [weak self] in
            self?.onNewPaymentMethodRequested?()
        }
        navigationItem.title = "Cards"
        navigationItem.largeTitleDisplayMode = .automatic
        view.backgroundColor = .systemBackgroundCompat
        
        tableView.allowsSelection = false
        tableView.dataSource = self
        tableView.register(PaymentMethodTableCell.self)
        tableView.register(PaymentMethodAddCell.self)
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
        let addCells = cells.filter { cell in
            switch cell {
            case .addButton:
                return true
            case .paymentMethod:
                return false
            }
        }
        let paymentMethodCells = cells.filter { cell in
            switch cell {
            case .paymentMethod:
                return true
            case .addButton:
                return false
            }
        }
        
        let newCells = paymentMethodCells + [.paymentMethod(paymentMethod)] + addCells
        self.cells = newCells
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell: UITableViewCell
        let item = cells[indexPath.row]
        
        switch item {
        case .paymentMethod(let paymentMethod):
            let cell = tableView.dequeue(PaymentMethodTableCell.self, for: indexPath)
            
            cell.apply(paymentMethod)
            
            tableViewCell = cell
        case .addButton:
            let cell = tableView.dequeue(PaymentMethodAddCell.self, for: indexPath)
            
            cell.onTap = { [weak self] in
                self?.onNewPaymentMethodRequested?()
            }
            
            tableViewCell = cell
        }
        
        return tableViewCell
    }
}
