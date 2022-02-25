import UIKit

class TiledView<State : CellularAutomataState>: UIView {
    var sideLength: CGFloat = 0
    var widthAnchorConstraint: NSLayoutConstraint!
    var heightAnchorConstraint: NSLayoutConstraint!
    var state: State = State()
    let delta: CGFloat = 0.0000001

    
    init() {
        super.init(frame: .zero)
        widthAnchorConstraint = widthAnchor.constraint(equalToConstant: 0)
        heightAnchorConstraint = heightAnchor.constraint(equalToConstant: 0)
        backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0)
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSideLength(sideLength: CGFloat) {
        self.sideLength = sideLength
        tiledLayer.tileSize = CGSize(width: sideLength * contentScaleFactor, height: sideLength * contentScaleFactor)
    }
    
    override class var layerClass: AnyClass { CATiledLayer.self }
    
    var tiledLayer: CATiledLayer { get { layer as! CATiledLayer }}
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let point = state.viewport.origin + Point(x: Int((rect.origin.x + delta) / sideLength), y: Int((rect.origin.y + delta) / sideLength))
        let color = state[point] == .active ? UIColor.systemBlue.cgColor : UIColor.secondarySystemBackground.cgColor
        context.setFillColor(color)
        context.fillEllipse(in: CGRect(x: rect.origin.x + rect.width * 0.025, y: rect.origin.y + rect.height * 0.025, width: rect.width * 0.95, height: rect.height * 0.95))
    }
    
    func updateSize() {
        widthAnchorConstraint.constant = CGFloat(state.viewport.size.width) * sideLength
        heightAnchorConstraint.constant = CGFloat(state.viewport.size.height) * sideLength
        tiledLayer.setNeedsDisplay()
    }
    
    func resize(width: Int, height: Int) {
        state.viewport = Rect(origin: state.viewport.origin, size: Size(width: width, height: height))
        updateSize()
    }
}
