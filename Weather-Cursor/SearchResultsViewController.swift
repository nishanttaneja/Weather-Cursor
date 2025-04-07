import UIKit
import Combine
import CoreLocation

class SearchResultsViewController: UIViewController {
    private let viewModel: WeatherViewModel
    private var locations: [Location] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "CityCell")
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        return table
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.text = "No cities found.\nTry searching with just the city name (e.g., Mumbai, Delhi)\nor add ', India' to your search."
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    init(viewModel: WeatherViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        view.addSubview(backgroundView)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(noResultsLabel)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            noResultsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noResultsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noResultsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            noResultsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupBindings() {
        viewModel.$searchResults
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locations in
                self?.locations = locations
                self?.tableView.reloadData()
                self?.noResultsLabel.isHidden = !locations.isEmpty
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
}

extension SearchResultsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell", for: indexPath)
        let location = locations[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        
        // Format the main text to include the city name
        content.text = location.name
        content.textProperties.color = .white
        content.textProperties.font = .systemFont(ofSize: 17, weight: .semibold)
        
        // Format the location details with state and country
        var locationDetails = [String]()
        if let state = location.state, !state.isEmpty {
            locationDetails.append(state)
        }
        locationDetails.append(location.country)
        
        content.secondaryText = locationDetails.joined(separator: ", ")
        content.secondaryTextProperties.color = .lightGray
        content.secondaryTextProperties.font = .systemFont(ofSize: 14, weight: .regular)
        
        // Add spacing between lines
        content.textToSecondaryTextVerticalPadding = 4
        
        cell.contentConfiguration = content
        cell.backgroundColor = .clear
        
        // Add selection style
        let backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        cell.selectedBackgroundView = backgroundView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let location = locations[indexPath.row]
        print("Selected city: \(location.name), \(location.country)")
        
        let clLocation = CLLocation(latitude: location.lat, longitude: location.lon)
        Task {
            await viewModel.fetchWeather(for: clLocation, cityName: location.name)
        }
        
        // Dismiss the search controller
        if let searchController = parent as? UISearchController {
            searchController.isActive = false
        }
    }
} 