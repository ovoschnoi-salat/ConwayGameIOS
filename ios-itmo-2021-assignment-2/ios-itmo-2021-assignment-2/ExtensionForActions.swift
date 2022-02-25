import UIKit

extension MainScreenViewController {
    //common
    internal func setupActionView() {
        contentView.addSubview(actionView)
        actionView.setupSideLength(sideLength: sideLength)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressInside))
        longPressRecognizer.minimumPressDuration = 0.2
        actionView.addGestureRecognizer(longPressRecognizer)
        
        selectionToolBarItems = [
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down.on.square"), primaryAction: UIAction(handler: saveSelectionAction)),
            .flexibleSpace(),
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.slash"), primaryAction: UIAction(handler: clearSelectionAction)),
            .flexibleSpace()
        ]
        
        insertionToolBarItems = [
            .flexibleSpace(),
            UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), primaryAction: UIAction(handler: insertAction)),
            .flexibleSpace()
        ]
    }
    
    internal func moveScrollViewOnShift(_ sender: UILongPressGestureRecognizer){
        let point = sender.location(in: view)
        var moveOffset: CGPoint = scrollView.contentOffset
        let offset: CGFloat = 50
        let acceleration: CGFloat = 0.7
        let topPadding = view.safeAreaLayoutGuide.layoutFrame.origin.y
        let bottomPadding = view.frame.height - topPadding - view.safeAreaLayoutGuide.layoutFrame.height + toolBar.frame.height
        if scrollView.contentSize.width > scrollView.frame.width {
            if point.x < offset {
                moveOffset.x += (point.x - offset) * acceleration
            } else if point.x > view.frame.width - offset {
                moveOffset.x += (point.x - view.frame.width + offset) * acceleration
            }
            moveOffset.x = min(scrollView.contentSize.width - scrollView.frame.width, moveOffset.x)
            moveOffset.x = max(0, moveOffset.x)
        }
        if automatonView.frame.height > scrollView.frame.height - topPadding - bottomPadding {
            if point.y < topPadding + offset {
                moveOffset.y += (point.y - topPadding - offset) * acceleration
            } else if point.y > view.frame.height - bottomPadding - offset {
                moveOffset.y += (point.y - view.frame.height + offset + bottomPadding) * acceleration
            }
            moveOffset.y = min(scrollView.contentSize.height - scrollView.frame.height + bottomPadding, moveOffset.y)
            moveOffset.y = max(-topPadding, moveOffset.y)
        }
        UIView.animate(withDuration: 0.05, delay: 0) {
            self.scrollView.contentOffset = moveOffset
        }
    }
    
    internal func setNavBarItems(title: String, menuEnabled: Bool, doneAction: @escaping (UIAction) -> Void){
        navigationItem.leftBarButtonItem?.primaryAction = UIAction(handler: doneAction)
        let fadeTextAnimation = CATransition()
        fadeTextAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fadeTextAnimation.duration = 0.2
        fadeTextAnimation.type = .fade
        navigationController?.navigationBar.layer.add(fadeTextAnimation, forKey: "fadeText")
        navigationItem.title = title
        self.navigationItem.rightBarButtonItem?.isEnabled = menuEnabled
    }
    
    internal func endAction(_: UIAction) {
        setNavBarItems(title: title ?? "", menuEnabled: true, doneAction: exitAction)
        UIView.animate(withDuration: 0.2, delay: 0, animations: {
            self.actionView.dissapear()
            self.toolBar.setItems(self.defaultToolBarItems, animated: true)
        }) { _ in
            self.actionView.hide()
        }
        automatonView.isUserInteractionEnabled = true
    }
    
    //selection
    
    internal func clearSelectionAction(action: UIAction) {
        let rect = Rect(origin: actionView.selectedFieldOrigin + automatonView.state.viewport.origin, size: actionView.selectedFieldSize)
        for y in rect.verticalIndices {
            for x in rect.horizontalIndices {
                automatonView.state[Point(x: x, y: y)] = .inactive
            }
        }
        automatonView.tiledLayer.setNeedsDisplay(actionView.frame)
    }
    
    internal func saveSelectionAction(action: UIAction) {
        let alertController = UIAlertController(title: "Save state", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.placeholder = "name"
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] (_) in
            guard let self = self else { return }
            var text = alertController.textFields![0].text ?? ""
            if text.count == 0 {
                text = "Saved state"
            }
            let rect = Rect(origin: self.actionView.selectedFieldOrigin + self.automatonView.state.viewport.origin, size: self.actionView.selectedFieldSize)
            var state = self.automatonView.state[rect]
            state.makeIndependent()
            
            let key = String(describing: State.self)
            var library: [StateData<State>] = []
            do {
                let data = UserDefaults.standard.data(forKey: key) ?? Data()
                library = try PropertyListDecoder().decode([StateData<State>].self, from: data)
            } catch {}
            library.append(StateData<State>(name: text, state: state))
            let encodedData = try! PropertyListEncoder().encode(library)
            UserDefaults.standard.set(encodedData, forKey: key)
        })
        present(alertController, animated: true)
    }
    
    
    //library and insertion
    internal func insertAction(action: UIAction) {
        let rectOrigin = actionView.selectedFieldOrigin + automatonView.state.viewport.origin
        actionView.stateView.state.translate(to: rectOrigin - actionView.stateView.state.viewport.origin)
        let rect = Rect(origin: rectOrigin, size: actionView.selectedFieldSize)
        automatonView.state[rect] = actionView.stateView.state
        automatonView.tiledLayer.setNeedsDisplay(actionView.frame)
        endAction(action)
    }
    
    internal func insertFromLibraryAction(state: State) {
        let insertionSize = actionView.stateView.state.viewport.size
        let currentSize = automatonView.state.viewport.size
        if insertionSize.height > currentSize.height || insertionSize.width > currentSize.width {
            automatonView.resize(width: max(insertionSize.width, currentSize.width), height: max(insertionSize.height, currentSize.height))
        }
        let topPadding = view.safeAreaLayoutGuide.layoutFrame.origin.y
        let point = CGPoint(x: scrollView.contentOffset.x / scrollView.zoomScale, y: (scrollView.contentOffset.y + topPadding) / scrollView.zoomScale)
        actionView.startInsertion(with: state, at: point, automatonWidth: automatonView.widthAnchorConstraint.constant, automatonHeight: automatonView.heightAnchorConstraint.constant)
        setNavBarItems(title: "Insertion", menuEnabled: false, doneAction: endAction)
        UIView.animate(withDuration: 0.2, delay: 0, animations: {
            self.actionView.show()
            self.toolBar.setItems(self.insertionToolBarItems, animated: true)
        })
        automatonView.isUserInteractionEnabled = false
    }
}

extension CGPoint {
    public static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    public static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
