struct CoordinatorLocation {
    let frameIndex: Int
    let navigationFrameIndex: Int?
}

func min(_ loc1: CoordinatorLocation, _ loc2: CoordinatorLocation) -> CoordinatorLocation {
    if loc1.frameIndex > loc2.frameIndex {
        return loc2
    } else if loc1.frameIndex == loc2.frameIndex {
        
        switch (loc1.navigationFrameIndex, loc2.navigationFrameIndex) {
        case (nil, nil):
            return loc1
        case (.some, .none):
            return loc2
        case (.none, .some):
            return loc1
        case (.some(let nav1), .some(let nav2)):
            if nav1 > nav2 {
                return loc2
            } else if nav1 == nav2 {
                return loc1
            } else {
                return loc1
            }
        }
    } else {
        return loc1
    }
}
