import UIKit

extension MainScreenViewController {
    internal func showLibraryAction(action: UIAction) {
        navigationController?.pushViewController(LibraryVC<State>(addStateAction: insertFromLibraryAction), animated: true)
    }
}

class LibraryVC<State: CellularAutomataState>: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var library: [StateData<State>] = []
    let tableView: UITableView = UITableView()
    let sideLength: CGFloat = 150
    var addState: ((State) -> Void)? = nil
    
    init(addStateAction: @escaping (State) -> Void) {
        super.init(nibName: nil, bundle: nil)
        addState = addStateAction
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        title = "Library"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AutomatonCell<State>.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = sideLength
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let key = String(describing: State.self)
        do {
            let data = UserDefaults.standard.data(forKey: key) ?? Data()
            library = try PropertyListDecoder().decode([StateData<State>].self, from: data)
        } catch {
            library = []
        }
        tableView.reloadData()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        library.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AutomatonCell<State>
        cell.title.text = library[indexPath.item].name
        let size = library[indexPath.item].state.viewport.size
        let minSide = max(size.height, size.width)
        cell.preview.setupSideLength(sideLength: sideLength/CGFloat(minSide))
        cell.preview.state = library[indexPath.item].state
        return cell
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] action,_,_ in
            guard let self = self else { return }
            self.showDeleteAlert(for: indexPath)
        }
        deleteAction.image = UIImage(systemName: "trash")
        let swipeAction = UISwipeActionsConfiguration(actions: [deleteAction])
        swipeAction.performsFirstActionWithFullSwipe = false
        return swipeAction
    }
    
    private func showDeleteAlert(for indexPath: IndexPath){
        let alertController = UIAlertController(title: "Delete Automaton", message: "Are you sure you want to delete the automaton?", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.library.remove(at: indexPath.item)
            let encodedData: Data
            do {
                encodedData = try PropertyListEncoder().encode(self.library)
            } catch {
                return
            }
            UserDefaults.standard.set(encodedData, forKey: String(describing: State.self))
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        })
        self.present(alertController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let selectAutomaton = addState else { return }
        selectAutomaton(library[indexPath.row].state)
        navigationController?.popViewController(animated: true)
    }
}

class AutomatonCell<State: CellularAutomataState>: UITableViewCell {
    var preview: TiledView<State> = TiledView<State>()
    var title: UILabel = UILabel()
    private let sideLength: CGFloat = 150
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        preview.translatesAutoresizingMaskIntoConstraints = false
        title.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(preview)
        contentView.addSubview(title)
        preview.widthAnchorConstraint.constant = sideLength
        preview.heightAnchorConstraint.constant = sideLength
        NSLayoutConstraint.activate([
            preview.widthAnchorConstraint,
            preview.heightAnchorConstraint,
            preview.topAnchor.constraint(equalTo: contentView.topAnchor),
            preview.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            preview.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            preview.rightAnchor.constraint(equalTo: title.leftAnchor, constant: -10),
            title.topAnchor.constraint(equalTo: contentView.topAnchor),
            title.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct StateData<State: CellularAutomataState>: Codable {
    let name: String
    let state: State
}

