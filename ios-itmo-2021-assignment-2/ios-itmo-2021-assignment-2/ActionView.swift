import UIKit

class ActionView<State: CellularAutomataState>: UIView {
    var stateView: TiledView<State> = TiledView<State>()
    var topConstraint: NSLayoutConstraint = NSLayoutConstraint()
    var leftConstraint: NSLayoutConstraint = NSLayoutConstraint()
    var widthConstraint: NSLayoutConstraint = NSLayoutConstraint()
    var heightConstraint: NSLayoutConstraint = NSLayoutConstraint()
    private var startPoint: CGPoint = .zero
    private var sideLength: CGFloat = 0
    private var automatonWidth: CGFloat = 0
    private var automatonHeight: CGFloat = 0
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.6).cgColor
        layer.borderWidth = 3
        layer.cornerRadius = 10
        isHidden = true
        alpha = 0
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSideLength(sideLength: CGFloat) {
        self.sideLength = sideLength
        stateView.setupSideLength(sideLength: sideLength)
    }
    
    func show() {
        isUserInteractionEnabled = true
        isHidden = false
        alpha = 1
    }
    
    func dissapear() {
        alpha = 0
    }
    
    func hide() {
        stateView.removeFromSuperview()
        frame = .zero
        isHidden = true
        isUserInteractionEnabled = false
    }
    
    //selection
    var selectedFieldOrigin: Point {
        get {
            if isHidden {
                return .zero
            }
            let x = Int(frame.origin.x / sideLength)
            let y = Int(frame.origin.y / sideLength)
            return Point(x: x, y: y)
        }
    }
    
    var selectedFieldSize: Size {
        get {
            if isHidden {
                return .zero
            }
            let width = Int(frame.width / sideLength)
            let height = Int(frame.height / sideLength)
            return Size(width: width, height: height)
        }
    }
    
    func startSelection(at point: CGPoint, automatonWidth: CGFloat, automatonHeight: CGFloat) {
        let x = point.x - point.x.truncatingRemainder(dividingBy: sideLength)
        let y = point.y - point.y.truncatingRemainder(dividingBy: sideLength)
        startPoint = CGPoint(x: x, y: y)
        self.automatonWidth = automatonWidth
        self.automatonHeight = automatonHeight
        frame = CGRect(origin: startPoint, size: CGSize(width: sideLength, height: sideLength))
    }
    
    func include(point: CGPoint) {
        var x = min(max(point.x, 0), automatonWidth - 1)
        var y = min(max(point.y, 0), automatonHeight - 1)
        x = x - x.truncatingRemainder(dividingBy: sideLength)
        y = y - y.truncatingRemainder(dividingBy: sideLength)
        let minX = min(x, startPoint.x)
        let minY = min(y, startPoint.y)
        let maxX = max(x, startPoint.x)
        let maxY = max(y, startPoint.y)
        let width = maxX - minX + sideLength
        let height = maxY - minY + sideLength
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.frame = CGRect(origin: CGPoint(x: minX, y: minY), size: CGSize(width: width, height: height))
        }
    }
    
    //insertion
    func startInsertion(with state: State, at point: CGPoint, automatonWidth: CGFloat, automatonHeight: CGFloat) {
        self.automatonWidth = automatonWidth
        self.automatonHeight = automatonHeight
        addSubview(stateView)
        NSLayoutConstraint.activate([
            stateView.topAnchor.constraint(equalTo: topAnchor),
            stateView.leftAnchor.constraint(equalTo: leftAnchor),
            stateView.widthAnchorConstraint,
            stateView.heightAnchorConstraint
        ])
        stateView.state = state
        stateView.updateSize()
        frame = CGRect(origin: .zero, size: CGSize(width: stateView.widthAnchorConstraint.constant, height: stateView.heightAnchorConstraint.constant))
        startPoint = .zero
        move(to: point)
        moveEnded()
    }
    
    func startMovement(at point: CGPoint) {
        startPoint = point
    }
    
    func move(to point: CGPoint) {
        let newPoint = self.frame.origin + (point - self.startPoint)
        let x = min(max(newPoint.x, 0), automatonWidth - frame.size.width)
        let y = min(max(newPoint.y, 0), automatonHeight - frame.size.height)
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.frame = CGRect(origin: CGPoint(x: x, y: y), size: self.frame.size)
        }
    }
    
    func moveEnded() {
        var x = (frame.origin.x + sideLength / 2)
        var y = (frame.origin.y + sideLength / 2)
        x = x - x.truncatingRemainder(dividingBy: sideLength)
        y = y - y.truncatingRemainder(dividingBy: sideLength)
        UIView.animate(withDuration: 0.1, delay: 0) {
            self.frame = CGRect(origin: CGPoint(x: x, y: y), size: self.frame.size)
        }
    }
}
