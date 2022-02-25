import UIKit

class MainScreenViewController<Automata: CellularAutomata<State>, State: CellularAutomataState>: UIViewController, UIScrollViewDelegate {
    
    internal let someIntrestingRules: [UInt8] = [28, 30, 50, 54, 60, 62, 73, 90, 94, 102, 110, 126, 150, 158, 188, 190, 220, 222]
    internal let automaton: Automata = Automata()
    internal let automatonView: TiledView<State> = TiledView<State>()
    internal let sideLength: CGFloat = 50
    internal var isPlaying: Bool = false
    internal var playFunc: ((_: Timer) -> Void)?
    
    internal let actionView: ActionView<State> = ActionView<State>()
    
    internal var snapshotStates: [State] = []
    internal var snapshotChanged: Bool = false
    
    internal let contentView: UIView = UIView()
    internal let scrollView: UIScrollView = UIScrollView()
    
    internal let toolBar: UIToolbar = UIToolbar()
    internal var defaultToolBarItems: [UIBarButtonItem] = []
    internal var selectionToolBarItems: [UIBarButtonItem] = []
    internal var insertionToolBarItems: [UIBarButtonItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if Automata.self == GameOfLifeCellularAutomata.self {
            title = "Game of Life"
        } else {
            title = "Elementary automaton"
        }
        
        view.backgroundColor = UIColor.systemBackground
        
        playFunc = { [weak self] (_: Timer) -> Void in
            guard let self = self else { return }
            self.automatonView.isUserInteractionEnabled = false
            let oldOrigin = self.automatonView.state.viewport.origin
            let newState = self.automaton.simulate(self.automatonView.state, generations: 1)
            let newOffset = newState.viewport.origin - oldOrigin
            let offset = self.scrollView.contentOffset
            self.scrollView.contentOffset = CGPoint(x: offset.x - CGFloat(newOffset.x) * self.sideLength * self.scrollView.zoomScale, y: offset.y - CGFloat(newOffset.y) * self.sideLength * self.scrollView.zoomScale)
            self.automatonView.state = newState
            self.automatonView.updateSize()
            self.snapshotChanged = true;
            if (self.isPlaying) {
                guard let action = self.playFunc else { fatalError() }
                RunLoop.current.add(Timer(timeInterval: 0.1, repeats: false, block: action), forMode: .common)
            } else {
                self.automatonView.isUserInteractionEnabled = true
            }
        }
        
        setupNavBar()
        setupScrollView()
        setupAutomataView()
        setupActionView()
        setupToolBar()
    }
    
    @objc internal func tap(_ sender: UITapGestureRecognizer) {
        let cgpoint = sender.location(in: automatonView)
        let viewPoint = Point(x: Int(cgpoint.x / sideLength), y: Int(cgpoint.y / sideLength))
        let point = automatonView.state.viewport.origin + viewPoint
        automatonView.state[point] = automatonView.state[point] == .active ? .inactive : .active
        automatonView.tiledLayer.setNeedsDisplay(CGRect(x: CGFloat(viewPoint.x) * sideLength, y: CGFloat(viewPoint.y) * sideLength, width: sideLength, height: sideLength))
        
        snapshotChanged = true
    }
    
    internal func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 3
        scrollView.delegate = self
        view.addSubview(scrollView)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 44, right: 0)
        NSLayoutConstraint.activate([
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leftAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
        ])
    }
    
    internal func setupAutomataView() {
        contentView.addSubview(automatonView)
        let height: Int = State.self == TwoDimensionalCellularAutomataState.self ? 15 : 1
        automatonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressOutside))
        longPressRecognizer.minimumPressDuration = 0.35
        automatonView.addGestureRecognizer(longPressRecognizer)
        automatonView.setupSideLength(sideLength: sideLength)
        automatonView.resize(width: 10, height: height)
        NSLayoutConstraint.activate([
            automatonView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            automatonView.topAnchor.constraint(equalTo: contentView.topAnchor),
            automatonView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            automatonView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            automatonView.heightAnchorConstraint,
            automatonView.widthAnchorConstraint
        ])
    }

    internal func setupToolBar() {
        view.addSubview(toolBar)
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toolBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            toolBar.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        
        defaultToolBarItems = [
            UIBarButtonItem(image: UIImage(systemName: "camera.viewfinder"), primaryAction: UIAction(handler: snapshotAction)),
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"), primaryAction: UIAction(handler: backwardAction)),
            UIBarButtonItem(image: UIImage(systemName: "play"), primaryAction: UIAction(handler: playAction)),
            UIBarButtonItem(image: UIImage(systemName: "forward.frame"), primaryAction: UIAction(handler: forwardAction)),
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "plus"), primaryAction: UIAction(handler: showLibraryAction))
        ]
        
        toolBar.setItems(defaultToolBarItems, animated: false)
    }
    
    
    internal func playAction(action: UIAction) {
        isPlaying = !isPlaying
        self.automatonView.isUserInteractionEnabled = !isPlaying
        defaultToolBarItems[0].isEnabled = !isPlaying
        defaultToolBarItems[2].isEnabled = !isPlaying
        defaultToolBarItems[4].isEnabled = !isPlaying
        defaultToolBarItems[6].isEnabled = !isPlaying
        defaultToolBarItems[3].image = isPlaying == false ? UIImage(systemName: "play") : UIImage(systemName: "pause")
        view.layoutIfNeeded()
        if (self.isPlaying) {
            guard let action = self.playFunc else { fatalError() }
            RunLoop.current.add(Timer(timeInterval: 0.1, repeats: false, block: action), forMode: .default)
        }
    }
    
    internal func snapshotAction(action: UIAction) {
        snapshotStates.append(automatonView.state)
    }
    
    internal func forwardAction(action: UIAction) {
        guard let action = self.playFunc else { fatalError() }
        RunLoop.current.add(Timer(timeInterval: 0, repeats: false, block: action), forMode: .default)
    }
    
    internal func backwardAction(action: UIAction) {
        if !snapshotChanged {
            let _ = snapshotStates.popLast()
        }
        guard let state = snapshotStates.last else { return }
        automatonView.state = state
        snapshotChanged = false
        automatonView.updateSize()
    }
    
    internal func resizeAction(action: UIAction) {
        let alertController = UIAlertController(title: "Resize field", message: "current size: \(automatonView.state.viewport.size.width)*\(automatonView.state.viewport.size.height)", preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "width"
            textField.keyboardType = .numberPad
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "height"
            textField.keyboardType = .numberPad
        }
        alertController.addAction(UIAlertAction(title: "Resize", style: .destructive) { [weak self] (_) in
            guard let self = self,
                  let width = alertController.textFields?.first?.text,
                  let height = alertController.textFields?[1].text,
                  let CGWidth = NumberFormatter().number(from: width),
                  let CGHeight = NumberFormatter().number(from: height)
            else { return }
            self.automatonView.resize(width: Int(truncating: CGWidth), height: Int(truncating: CGHeight))
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    internal func clearAction(action: UIAction) {
        let alertController = UIAlertController(title: "Unsaved changes", message: "Are you sure you want to clear the field?\nAll unsaved changes will be lost!", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            let width = self.automatonView.state.viewport.size.width
            let height = self.automatonView.state.viewport.size.height
            self.automatonView.state = State()
            self.automatonView.resize(width: width, height: height)
        })
        present(alertController, animated: true)
    }
    
    internal func elementaryAction(action: UIAction) {
        navigationController?.selectAutomataAction(game: MainScreenViewController<ElementaryCellularAutomata, ElementaryCellularAutomataState>(), gameName: "Elementary automaton")
    }
    
    internal func golAction(action: UIAction) {
        navigationController?.selectAutomataAction(game: MainScreenViewController<GameOfLifeCellularAutomata, TwoDimensionalCellularAutomataState>(), gameName: "Game of life automaton")
    }

    internal func setupNavBar() {
        let exitButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: nil)
        exitButton.primaryAction = UIAction(handler: exitAction)
        navigationItem.leftBarButtonItem = exitButton
        var navBarMenu = [
            UIMenu(title: "New automaton", image: UIImage(systemName: "gearshape"), children: [
                UIAction(title: "Elementary", handler: elementaryAction),
                UIAction(title: "Game of life", handler: golAction)
            ]),
            UIAction(title: "Resize", image: UIImage(systemName: "crop"), handler: resizeAction),
            UIAction(title: "Clear", image: UIImage(systemName: "xmark.octagon"), attributes: .destructive, handler: clearAction),
            UIMenu(title: "Appearence mode", image: UIImage(systemName: "circle.righthalf.filled"), children: [
                UIAction(title: "Light", handler: ChangeAppearenceModeAction(to: .light)),
                UIAction(title: "Dark", handler: ChangeAppearenceModeAction(to: .dark)),
                UIAction(title: "OS default", handler: ChangeAppearenceModeAction(to: .unspecified)),
            ])
        ]
        if State.self == ElementaryCellularAutomataState.self {
            navBarMenu.insert(UIAction(title: "Set new rule",handler: setNewRuleAction), at: 1)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .edit, menu: UIMenu(title: "", children: navBarMenu))
    }
    
    internal func setNewRuleAction(_: UIAction) {
        guard State.self == ElementaryCellularAutomataState.self else { return }
        
        let alertController = UIAlertController(title: "Set new elemetary cellular automata rule", message: "current rule is \((self.automaton as! ElementaryCellularAutomata).code)\nchoose rule from 0 to 255", preferredStyle: .alert)
        alertController.addTextField{ textField in
            textField.placeholder = "rule"
            textField.keyboardType = .numberPad
        }
        alertController.addAction(UIAlertAction(title: "Set", style: .default) { [weak self] (_) in
            guard let self = self,
                  let text = alertController.textFields?.first?.text,
                  let rule = NumberFormatter().number(from: text)
            else { return }
            let ruleUInt8 = UInt8(truncating: rule)
            if ruleUInt8 < 0 || ruleUInt8 > 255 { return }
            (self.automaton as! ElementaryCellularAutomata).code = ruleUInt8
        })
        alertController.addAction(UIAlertAction(title: "Random", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            (self.automaton as! ElementaryCellularAutomata).code = self.someIntrestingRules[Int.random(in: 0..<self.someIntrestingRules.count)]
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alertController, animated: true)
    }
    
    internal func exitAction(_: UIAction) {
        let alertController = UIAlertController(title: "Unsaved changes", message: "Are you sure you want to exit?\nAll unsaved changes will be lost!", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Exit", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        })
        present(alertController, animated: true)
    }
    
    internal func ChangeAppearenceModeAction(to style: UIUserInterfaceStyle) -> (UIAction) -> Void {
        return { [weak self] (_: UIAction) -> Void in
            guard let self = self else { return }
            let styleAnimation = CATransition()
            styleAnimation.duration = 0.1
            styleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            styleAnimation.type = .fade
            self.view.layer.add(styleAnimation, forKey: "styleAnimation")
            self.view.window?.overrideUserInterfaceStyle = style
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { contentView }
    
    
    
    @objc internal func longPressOutside(_ sender: UILongPressGestureRecognizer){
        if sender.state == .began {
            let point = sender.location(in: automatonView)
            actionView.startSelection(at: point, automatonWidth: automatonView.widthAnchorConstraint.constant, automatonHeight: automatonView.heightAnchorConstraint.constant)
            setNavBarItems(title: "Edit", menuEnabled: false, doneAction: endAction)
            UIView.animate(withDuration: 0.2, delay: 0, animations: {
                self.actionView.show()
                self.toolBar.setItems(self.selectionToolBarItems, animated: true)
            })
        } else if sender.state == .changed {
            let point = sender.location(in: automatonView)
            actionView.include(point: point)
            moveScrollViewOnShift(sender)
        }
    }
    
    
    @objc internal func longPressInside(_ sender: UILongPressGestureRecognizer){
        if sender.state == .began {
            let point = sender.location(in: actionView)
            actionView.startMovement(at: point)
        } else if sender.state == .changed {
            let point = sender.location(in: actionView)
            actionView.move(to: point)
            moveScrollViewOnShift(sender)
        } else {
            actionView.moveEnded()
        }
    }
}
