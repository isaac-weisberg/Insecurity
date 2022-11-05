protocol CommonModalCoordinatorV2: AnyObject {
    
}

struct WeakCommonModalCoordinatorV2 {
    weak var value: CommonModalCoordinatorV2?
    
    init(_ value: CommonModalCoordinatorV2) {
        self.value = value
    }
}
