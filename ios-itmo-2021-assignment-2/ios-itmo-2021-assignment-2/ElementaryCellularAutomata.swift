struct ElementaryCellularAutomataState : CellularAutomataState, CustomStringConvertible, Codable {
    typealias State = ElementaryCellularAutomataState
    typealias Cell = BinaryCell
    
    private var array: [Cell] = Array(repeating: .inactive, count: 0)
    private var outerValues: [Cell] = Array(repeating: .inactive, count: 0)
    private var isSubState: Bool = false
    private var subViewport: Rect = .zero
    private var _viewport: Rect = .zero
    var viewport: Rect {
        get {
            _viewport
        }
        set {
            var (newArray, newOuterValues) = Self.initArrays(withRect: newValue)
            if let area = newValue & _viewport {
                let verticalIndices = area.verticalIndices
                let newFrom = verticalIndices.lowerBound - newValue.origin.y
                let newTo = verticalIndices.upperBound - newValue.origin.y
                let oldFrom = verticalIndices.lowerBound - _viewport.origin.y
                let oldTo = verticalIndices.upperBound - _viewport.origin.y
                newOuterValues[newFrom..<newTo] = outerValues[oldFrom..<oldTo]
                for y in verticalIndices {
                    let fromPoint = Point(x: area.firstHIndex, y: y)
                    let toPoint = Point(x: area.lastHIndex, y: y)
                    let newBeginning = Point(x: newValue.firstHIndex, y: y).toIndex(in: newValue)
                    let newFrom = fromPoint.toIndex(in: newValue)
                    let newTo = toPoint.toIndex(in: newValue)
                    let newEnding = Point(x: newValue.lastHIndex, y: y).toIndex(in: newValue)
                    let oldFrom = fromPoint.toIndex(in: _viewport)
                    let oldTo = toPoint.toIndex(in: _viewport)
                    newArray.replaceSubrange(newBeginning..<newFrom, with: Array(repeating: newOuterValues[y - newValue.origin.y], count: newFrom - newBeginning))
                    newArray[newFrom..<newTo] = array[oldFrom..<oldTo]
                    newArray.replaceSubrange(newTo..<newEnding, with: Array(repeating: newOuterValues[y - newValue.origin.y], count: newEnding - newTo))
                }
            }
            array = newArray
            outerValues = newOuterValues
            _viewport = newValue
        }
    }
    
    init() {}
    
    init(rect: Rect) {
        _viewport = rect
        (array, outerValues) = Self.initArrays(withRect: _viewport)
    }
    
    init(state: State) {
        array = state.array
        _viewport = state.viewport
        outerValues = state.outerValues
    }
    
    private init(state: State, rect: Rect) {
        array = state.array
        _viewport = state.viewport
        outerValues = state.outerValues
        isSubState = true
        subViewport = rect
    }
    
    private static func initArrays(withRect rect: Rect) -> ([Cell], [Cell]) {
        (newArray(rect.square()), newArray(rect.size.height))
    }
    
    private static func newArray(_ size: Int) -> [Cell] {
        Array(repeating: .inactive, count: size)
    }
    
    mutating func makeIndependent() {
        if isSubState {
            viewport = subViewport
            outerValues = Self.newArray(outerValues.count)
            isSubState = false
        }
    }
    
    private func getOuterValue(at point: Point) -> Cell {
        guard viewport.verticalIndices.contains(point.y) else { return .inactive }
        return outerValues[point.y - viewport.origin.y]
    }
    
    subscript(y: Int) -> Cell {
        get {
            if isSubState {
                guard subViewport.verticalIndices.contains(y) else { return .inactive }
            }
            guard viewport.verticalIndices.contains(y) else { return .inactive }
            let index = y - viewport.origin.y
            return outerValues[index]
        }
        set {
            guard self[y] != newValue else { return }
            makeIndependent()
            guard viewport.verticalIndices.contains(y) else {
                viewport = viewport.expandedUp(by: y - (viewport.verticalIndices.last ?? -1))
                let index = y - viewport.origin.y
                outerValues[index] = newValue
                return
            }
            let index = y - viewport.origin.y
            outerValues[index] = newValue
        }
    }
    
    subscript(coordinates: Point) -> BinaryCell {
        get {
            if isSubState {
                guard subViewport.contains(coordinates) else { return .inactive }
            }
            if viewport.contains(coordinates) {
                let index = coordinates.toIndex(in: viewport)
                return array[index]
            } else {
                return getOuterValue(at: coordinates)
            }
        }
        set {
            guard self[coordinates] != newValue else { return }
            makeIndependent()
            if !viewport.contains(coordinates) {
                viewport = viewport.including(coordinates)
            }
            let index = coordinates.toIndex(in: viewport)
            array[index] = newValue
        }
    }
    
    subscript(newRect: Rect) -> State {
        get {
            return State(state: self, rect: newRect)
        }
        set {
            if isSubState && !subViewport.contains(newRect) {
                makeIndependent()
            }
            viewport = viewport | newRect
            for y in newRect.verticalIndices {
                for x in newRect.horizontalIndices {
                    let point = Point(x: x, y: y)
                    let index = point.toIndex(in: viewport)
                    array[index] = newValue[point]
                }
            }
        }
    }
    
    mutating func translate(to: Point) {
        if isSubState {
            subViewport = subViewport + to
        }
        _viewport = _viewport + to
    }
    
    public var description: String {
        return (isSubState ? subViewport : viewport).map(f: { p -> String in self[p] == .active ? "█" : " " })
    }
}

class ElementaryCellularAutomata: CellularAutomata<ElementaryCellularAutomataState> {
    typealias State = ElementaryCellularAutomataState
    typealias Cell = BinaryCell
    
    var code: UInt8
    
    required init() {
        code = 1
    }
    
    init(rule: UInt8) {
        code = rule
    }
    
    override func simulate(_ oldState: State, generations: UInt) -> State {
        var state = oldState
        let y = state.viewport.lastVIndex - 1
        let oldViewport = state.viewport
        guard state.viewport.square() > 0 else {
            for index in y ..< y + Int(generations) {
                if state[index] == .inactive {
                    if code & 0b1 == 0 {
                        break
                    }
                    state[index + 1] = .active
                } else if code & 0b10000000 != 0 {
                    state[index + 1] = .active
                }
            }
            return state
        }
        for index in y ..< y + Int(generations) {
            if state[index] == .inactive && code & 0b1 != 0 {
                state[index + 1] = .active
            } else if state[index] == .active && code & 0b10000000 != 0 {
                state[index + 1] = .active
            }
            for x in state.viewport.nextHorizontalIndices {
                let l = state[Point(x: x-1, y: index)].rawValue
                let m = state[Point(x: x, y: index)].rawValue
                let r = state[Point(x: x+1, y: index)].rawValue
                let st = l<<2 | m<<1 | r
                state[Point(x: x, y: index + 1)] = code & (1 << st) != 0 ? .active : .inactive
            }
        }
        if state.viewport == oldViewport {
            state.viewport = oldViewport.expandedUp(by: Int(generations))
        }
        return state
    }
}
