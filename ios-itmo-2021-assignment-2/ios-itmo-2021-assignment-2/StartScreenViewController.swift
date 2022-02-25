import UIKit

class StartScreenViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let button1 = UIButton()
        button1.configuration = UIButton.Configuration.filled()
        button1.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button1)
        
        button1.setTitle("Start Game of Life", for: .normal)
        NSLayoutConstraint.activate([
            button1.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button1.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        button1.addTarget(self, action: #selector(showGoL), for: .touchUpInside)
        
        let button2 = UIButton()
        button2.configuration = UIButton.Configuration.filled()
        button2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button2)
        
        button2.setTitle("Start Elemetary", for: .normal)
        NSLayoutConstraint.activate([
            button2.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button2.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 100)
        ])
        button2.addTarget(self, action: #selector(showElementary), for: .touchUpInside)
        view.backgroundColor = UIColor.systemBackground
    }
    
    
    
    @objc private func showGoL() {
        show(vc: MainScreenViewController<GameOfLifeCellularAutomata, TwoDimensionalCellularAutomataState>())
    }
    
    @objc private func showElementary() {
        show(vc: MainScreenViewController<ElementaryCellularAutomata, ElementaryCellularAutomataState>())
    }
    
    private func show(vc: UIViewController) {
        let controller = UINavigationController(rootViewController: vc)
            controller.modalPresentationStyle = .fullScreen
            self.show(controller, sender: self)
    }
    
}

