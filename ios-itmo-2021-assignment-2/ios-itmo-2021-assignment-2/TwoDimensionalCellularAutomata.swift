struct TwoDimensionalCellularAutomataState : CellularAutomataState, CustomStringConvertible, Codable {
    typealias State = TwoDimensionalCellularAutomataState
    typealias Cell = BinaryCell
    
    private var array: [Cell] = Array(repeating: .inactive, count: 0)
    var outerValue: Cell = .inactive
    private var isSubState: Bool = false
    private var subViewport: Rect = .zero
    private var _viewport: Rect = .zero
    
    var viewport: Rect {
        get {
            _viewport
        }
        set {
            var newArray = newArray(newValue.square())
            if let area = newValue & _viewport {
                for y in area.verticalIndices {
                    let fromPoint = Point(x: area.firstHIndex, y: y)
                    let toPoint = Point(x: area.lastHIndex, y: y)
                    let newFrom = fromPoint.toIndex(in: newValue)
                    let newTo = toPoint.toIndex(in: newValue)
                    let oldFrom = fromPoint.toIndex(in: _viewport)
                    let oldTo = toPoint.toIndex(in: _viewport)
                    newArray[newFrom..<newTo] = array[oldFrom..<oldTo]
                }
            }
            array = newArray
            _viewport = newValue
        }
    }
    
    init() {}
    
    init(rect: Rect) {
        _viewport = rect
        array = newArray(rect.square())
    }
    
    init(rect: Rect, defaultValue: Cell) {
        _viewport = rect
        outerValue = defaultValue
        array = newArray(rect.square())
    }
    
    init(state: State) {
        array = state.array
        _viewport = state.viewport
        outerValue = state.outerValue
    }
    
    private init(state: State, rect: Rect) {
        array = state.array
        _viewport = state.viewport
        outerValue = state.outerValue
        isSubState = true
        subViewport = rect
    }
    
    private func newArray(_ size: Int) -> [Cell] {
        Array(repeating: outerValue, count: size)
    }
    
    mutating func makeIndependent() {
        if isSubState {
            viewport = subViewport
            outerValue = .inactive
            isSubState = false
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
                return outerValue
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
        return (isSubState ? subViewport : viewport).map(f: {(p: Point) -> String in self[p] == .active ? "█" : " " })
    }
}

class TwoDimensionalCellularAutomata: CellularAutomata<TwoDimensionalCellularAutomataState> {
    typealias State = TwoDimensionalCellularAutomataState
    typealias Cell = BinaryCell
    
    private var activeOuters: Cell
    private var inactiveOuters: Cell
    
    private var f: ([UInt8]) -> Cell
    
    private static func getNewOuters(_ f: ([UInt8]) -> Cell) -> (Cell, Cell) {
        return (f(Array(repeating: 1, count: 9)),f(Array(repeating: 0, count: 9)))
    }
    
    var function: ([UInt8]) -> Cell {
        get {
            f
        }
        set {
            f = newValue
            (activeOuters, inactiveOuters) = Self.getNewOuters(f)
        }
    }
    
    required init() {
        f = {(array:[UInt8]) -> Cell in
            let sum = array.reduce(0, { a, b -> UInt8 in a + b})
            if array[4] != 0 {
                return sum == 3 || sum == 4 ? .active : .inactive
            } else {
                return sum == 3 ? .active : .inactive
            }
        }
        (activeOuters, inactiveOuters) = Self.getNewOuters(f)
    }
    
    init(_ function: @escaping ([UInt8]) -> Cell) {
        f = function
        (activeOuters, inactiveOuters) = Self.getNewOuters(f)
    }
    
    override func simulate(_ state: State, generations: UInt) -> State {
        var state = state
        guard state.viewport.square() > 0 else {
            if activeOuters == .inactive {
                if inactiveOuters == .active {
                    if generations%2 == 1 {
                        state.outerValue = state.outerValue == .active ? .inactive : .active
                    }
                } else {
                    state.outerValue = .inactive
                }
            } else if inactiveOuters == .active {
                state.outerValue = .active
            }
            return state
        }
        for _ in 0..<generations {
            var newState = State(rect: state.viewport)
            if activeOuters == .inactive {
                if inactiveOuters == .active && generations % 2 == 1 && state.outerValue == .inactive {
                    newState.outerValue = .active
                }
            } else if inactiveOuters == .active {
                newState.outerValue = .active
            } else {
                newState.outerValue = state.outerValue
            }
            for y in state.viewport.nextVerticalIndices {
                for x in state.viewport.nextHorizontalIndices {
                    let array = (-1...1).reduce([], { sum, i in
                        sum + (-1...1).map({ j in
                            state[Point(x: x + j, y: y + i)].rawValue
                        })
                    })
                    newState[Point(x: x, y: y)] = f(array)
                }
            }
            state = newState
        }
        return state
    }
}

class GameOfLifeCellularAutomata: CellularAutomata<TwoDimensionalCellularAutomataState> {
    typealias State = TwoDimensionalCellularAutomataState
    typealias Cell = BinaryCell
    
    override func simulate(_ state: State, generations: UInt) -> State {
        var state = state
        guard state.viewport.square() > 0 else { return state }
        for _ in 0..<generations {
            var newState = State(rect: state.viewport)
            for y in state.viewport.nextVerticalIndices {
                for x in state.viewport.nextHorizontalIndices {
                    let sum = (-1...1).reduce(0, { res, i in
                        res + (-1...1).reduce(0, { res, j in
                            res + state[Point(x: x + j, y: y + i)].rawValue
                        })
                    })
                    if state[Point(x: x, y: y)] == .active {
                        if sum == 3 || sum == 4 {
                            newState[Point(x: x, y: y)] = .active
                        }
                    } else if sum == 3 {
                        newState[Point(x: x, y: y)] = .active
                    }
                }
            }
            state = newState
        }
        return state
    }
}
