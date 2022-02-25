extension Size: CustomStringConvertible{
    static let zero = Self(width: 0, height: 0)
    
    public var description: String {
        "[w:\(width) h:\(height)]"
    }
}

extension Point: CustomStringConvertible{
    static let zero = Self(x: 0, y: 0)
    
    func toIndex(in rect: Rect) -> Int {
        return (self.y - rect.origin.y) * rect.size.width + self.x - rect.origin.x
    }
    
    static func +(left: Point, right: Point) -> Point {
        return Point(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func -(left: Point, right: Point) -> Point {
        return Point(x: left.x - right.x, y: left.y - right.y)
    }
    
    public var description: String {
        "[x:\(x) y:\(y)]"
    }
}

extension Rect: CustomStringConvertible{
    static let zero = Rect(origin: .zero, size: .zero)
    
    var firstVIndex: Int {
        origin.y
    }
    
    var lastVIndex: Int {
        origin.y + size.height
    }
    
    var firstHIndex: Int {
        origin.x
    }
    
    var lastHIndex: Int {
        origin.x + size.width
    }
    
    static func &(left: Rect, right: Rect) -> Rect? {
        let maxX: Int = max(left.origin.x, right.origin.x)
        let minX: Int = min(left.origin.x + left.size.width, right.origin.x + right.size.width)
        let maxY: Int = max(left.origin.y, right.origin.y)
        let minY: Int = min(left.origin.y + left.size.height, right.origin.y + right.size.height)
        guard maxX <= minX && maxY <= minY else { return nil }
        return Rect(origin: Point(x: maxX, y: maxY), size: Size(width: minX - maxX, height: minY - maxY))
    }
    
    static func |(left: Rect, right: Rect) -> Rect {
        let minX: Int = min(left.origin.x, right.origin.x)
        let maxX: Int = max(left.origin.x + left.size.width, right.origin.x + right.size.width)
        let minY: Int = min(left.origin.y, right.origin.y)
        let maxY: Int = max(left.origin.y + left.size.height, right.origin.y + right.size.height)
        return Rect(origin: Point(x: minX, y: minY), size: Size(width: maxX - minX, height: maxY - minY))
    }
    
    static func +(left: Rect, right: Point) -> Rect {
        return Rect(origin: left.origin + right, size: left.size)
    }
    
    func including(_ point: Point) -> Rect {
        return self | Rect(origin: Point(x: point.x, y: point.y), size: Size(width: 1, height: 1))
    }
    
    func expandedUp(by height: Int) -> Rect {
        return Rect(origin: Point(x: origin.x, y: origin.y), size: Size(width: size.width, height: size.height + height))
    }
    
    func square() -> Int {
        return size.width * size.height
    }
    
    func contains(_ point: Point) -> Bool{
        firstHIndex <= point.x && point.x < lastHIndex && firstVIndex <= point.y && point.y < lastVIndex
    }
    
    func contains(_ rect: Rect) -> Bool{
        firstHIndex <= rect.firstHIndex && firstVIndex <= rect.firstVIndex &&
        lastHIndex >= rect.lastHIndex && lastVIndex >= rect.lastVIndex
    }
    
    var verticalIndices: Range<Int> {
        firstVIndex..<lastVIndex
    }
    
    var horizontalIndices: Range<Int> {
        firstHIndex..<lastHIndex
    }
    
    var nextVerticalIndices: ClosedRange<Int> {
        firstVIndex-1...lastVIndex
    }
    
    var nextHorizontalIndices: ClosedRange<Int> {
        firstHIndex-1...lastHIndex
    }
    
    func map(f: (Point) -> String) -> String {
        verticalIndices.map{ y in
            horizontalIndices.map{ x in
                f(Point(x: x, y: y))
            }.joined()
        }.joined(separator: "\n")
    }
    
    public var description: String {
        "( o:\(origin) s:\(size) )"
    }
}
