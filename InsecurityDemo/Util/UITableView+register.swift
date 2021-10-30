import UIKit

extension UITableView {
    func register(_ cellType: UITableViewCell.Type) {
        self.register(cellType, forCellReuseIdentifier: "\(cellType)")
    }
    
    func dequeue<CellType: UITableViewCell>(_ cellType: CellType.Type, for indexPath: IndexPath) -> CellType {
        return self.dequeueReusableCell(withIdentifier: "\(cellType)", for: indexPath) as! CellType
    }
}
