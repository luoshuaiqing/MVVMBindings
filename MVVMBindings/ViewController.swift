//
//  ViewController.swift
//  MVVMBindings
//
//  Created by Shuaiqing Luo on 11/17/23.
//

import UIKit

// MARK: - Observable

class Observable<T> {
    
    typealias ListenerHandler = (T) -> Void
    
    var value: T {
        didSet {
            listeners.forEach { $0(value) }
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    private var listeners: [ListenerHandler] = []
    
    func bind(_ listener: @escaping(ListenerHandler)) {
        listener(value)
        self.listeners.append(listener)
    }
}

// MARK: - Model

struct User: Codable {
    let name: String
}

// MARK: - ViewModel

struct UserListViewModel {
    var userViewModels: Observable<[UserTableViewCellViewModel]> = Observable([])
}

struct UserTableViewCellViewModel {
    let name: String
}

// MARK: - Controller

class ViewController: UIViewController, UITableViewDataSource {

    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let viewModel = UserListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.dataSource = self
        
        viewModel.userViewModels.bind { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
        
        fetchData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.userViewModels.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = viewModel.userViewModels.value[indexPath.row].name
        return cell
    }

    func fetchData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/users") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let userModels = try? JSONDecoder().decode([User].self, from: data)  else { return }
            self.viewModel.userViewModels.value = userModels.compactMap({
                UserTableViewCellViewModel(name: $0.name)
            })
        }
        
        task.resume()
    }
}

