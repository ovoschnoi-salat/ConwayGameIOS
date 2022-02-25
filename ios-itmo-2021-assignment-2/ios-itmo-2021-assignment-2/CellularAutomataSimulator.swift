public class CellularAutomata<State: CellularAutomataState> {
    required init() { }
    /// Возвращает новое состояние поля после n поколений
    /// - Parameters:
    ///   - state: Исходное состояние поля
    ///   - generations: Количество симулирвемых поколений
    /// - Returns:
    ///   - Новое состояние после симуляции
    func simulate(_ state: State, generations: UInt) -> State {state}
}

public protocol CellularAutomataState: Codable {

    /// Конструктор пустого поля
    init()

    /// Квадрат представляемой области в глобальных координатах поля
    /// Присвоение нового значение обрезая/дополняя поле до нужного размера
    var viewport: Rect { get set }

    /// Значение конкретной ячейки в точке, заданной в глобальных координатах.
    subscript(_: Point) -> BinaryCell { get set }
    /// Значение поля в прямоугольнике, заданном в глобальных координатах.
    subscript(_: Rect) -> Self { get set }

    /// Меняет origin у viewport
    mutating func translate(to: Point)
    mutating func makeIndependent()
}

public struct Size: Codable, Equatable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        guard width >= 0 && height >= 0 else { fatalError() }
        self.width = width
        self.height = height
    }
}

public struct Point: Codable, Equatable {
    public let x: Int
    public let y: Int
}

public struct Rect: Codable, Equatable {
    public let origin: Point
    public let size: Size
}

public enum BinaryCell: UInt8, Codable {
    case inactive = 0
    case active = 1
}
