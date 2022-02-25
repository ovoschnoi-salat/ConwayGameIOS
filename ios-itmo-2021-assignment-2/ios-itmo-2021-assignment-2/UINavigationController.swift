import UIKit

extension UINavigationController {
    func selectAutomataAction(game: UIViewController, gameName: String) {
        game.title = gameName
        let alertController = UIAlertController(title: "New automaton", message: "Are you sure you want to open new  \(gameName)?\nAll unsaved changes will be lost!", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Open", style: .destructive) { (_) in
            self.setViewControllers([game], animated: true)
        })
        present(alertController, animated: true)
    }
}
