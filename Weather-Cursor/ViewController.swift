//
//  ViewController.swift
//  Weather-Cursor
//
//  Created by Nishant Taneja on 07/04/25.
//

import UIKit
import CoreLocation
import Combine

class ViewController: UIViewController {
    private let viewModel = WeatherViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var searchResultsViewController: SearchResultsViewController?
    
    // MARK: - UI Components
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .dark)
        let view = UIVisualEffectView(effect: blur)
        view.alpha = 0.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cityLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 96, weight: .thin)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let weatherDescriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let weatherDetailsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    
    private let temperatureUnitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("°C", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let locationButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        let image = UIImage(systemName: "location.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        setupSearchController()
        setupBindings()
        viewModel.requestLocationPermission()
    }
    
    // MARK: - Setup Methods
    private func setupNavigationBar() {
        title = "Weather"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .black
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBlue
        
        view.addSubview(backgroundImageView)
        view.addSubview(blurView)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(cityLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(temperatureLabel)
        contentView.addSubview(weatherDescriptionLabel)
        contentView.addSubview(weatherDetailsStackView)
        contentView.addSubview(temperatureUnitButton)
        view.addSubview(errorLabel)
        view.addSubview(locationButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            cityLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cityLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cityLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            dateLabel.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 8),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            temperatureLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 20),
            temperatureLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            temperatureLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            temperatureUnitButton.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 8),
            temperatureUnitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            temperatureUnitButton.widthAnchor.constraint(equalToConstant: 60),
            temperatureUnitButton.heightAnchor.constraint(equalToConstant: 40),
            
            weatherDescriptionLabel.topAnchor.constraint(equalTo: temperatureUnitButton.bottomAnchor, constant: 8),
            weatherDescriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weatherDescriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            weatherDetailsStackView.topAnchor.constraint(equalTo: weatherDescriptionLabel.bottomAnchor, constant: 32),
            weatherDetailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weatherDetailsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weatherDetailsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            locationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            locationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        locationButton.addTarget(self, action: #selector(locationButtonTapped), for: .touchUpInside)
        temperatureUnitButton.addTarget(self, action: #selector(temperatureUnitButtonTapped), for: .touchUpInside)
    }
    
    private func setupSearchController() {
        searchResultsViewController = SearchResultsViewController(viewModel: viewModel)
        let searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.searchBar.placeholder = "Search for a city (e.g., Mumbai, Delhi, Bangalore)"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .white
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupBindings() {
        viewModel.$weatherData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in
                self?.updateUI(with: weather)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                if let message = message {
                    self?.showError(message)
                } else {
                    self?.hideError()
                }
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
    
    // MARK: - UI Updates
    private func updateUI(with weather: WeatherResponse?) {
        guard let weather = weather else {
            hideError()
            return
        }
        
        // Debug temperature values
        print("Raw temperature: \(weather.main.temp)°C")
        print("Feels like: \(weather.main.feelsLike)°C")
        print("Min temp: \(weather.main.tempMin)°C")
        print("Max temp: \(weather.main.tempMax)°C")
        print("Current unit: \(viewModel.temperatureUnit.rawValue)")
        print("Weather condition: \(weather.weather.first?.main ?? "unknown")")
        
        // Update background first to ensure it's visible
        updateBackground(for: weather)
        
        // Then update the rest of the UI
        cityLabel.text = viewModel.selectedCityName ?? weather.name
        dateLabel.text = weather.formattedDate
        temperatureLabel.text = viewModel.getTemperatureString(weather.main.temp)
        weatherDescriptionLabel.text = weather.weather.first?.description.capitalized
        
        updateWeatherDetails(with: weather)
        hideError()
    }
    
    private func updateWeatherDetails(with weather: WeatherResponse) {
        // Clear existing details
        weatherDetailsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new details
        let details = [
            ("Feels Like", viewModel.getTemperatureString(weather.main.feelsLike)),
            ("Humidity", "\(weather.main.humidity)%"),
            ("Wind", "\(Int(round(weather.wind.speed))) m/s \(weather.wind.direction)"),
            ("Sunrise", weather.sunriseTime),
            ("Sunset", weather.sunsetTime)
        ]
        
        for (title, value) in details {
            let row = createDetailRow(title: title, value: value)
            weatherDetailsStackView.addArrangedSubview(row)
        }
    }
    
    private func updateBackground(for weather: WeatherResponse) {
        let imageName = viewModel.getBackgroundImageName()
        print("Updating background to: \(imageName)")
        
        // Force a new image to be loaded
        let newImage = UIImage(named: imageName) ?? UIImage(named: "default_background")
        
        // Ensure we're on the main thread for UI updates
        DispatchQueue.main.async {
            UIView.transition(with: self.backgroundImageView,
                             duration: 0.5,
                             options: .transitionCrossDissolve,
                             animations: {
                self.backgroundImageView.image = newImage
            })
            
            // Update text colors based on background brightness
            self.updateTextColors(for: newImage)
        }
    }
    
    private func updateTextColors(for image: UIImage?) {
        guard let image = image else { return }
        
        // Create a small thumbnail to analyze
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let thumbnail = thumbnail,
              let cgImage = thumbnail.cgImage,
              let data = cgImage.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else {
            return
        }
        
        // Calculate average brightness
        var totalBrightness: CGFloat = 0
        let pixelCount = CFDataGetLength(data)
        
        for i in stride(from: 0, to: pixelCount, by: 4) {
            let r = CGFloat(bytes[i]) / 255.0
            let g = CGFloat(bytes[i + 1]) / 255.0
            let b = CGFloat(bytes[i + 2]) / 255.0
            
            // Calculate perceived brightness
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b)
            totalBrightness += brightness
        }
        
        let averageBrightness = totalBrightness / CGFloat(pixelCount / 4)
        
        // Update text colors based on background brightness
        let textColor: UIColor = averageBrightness > 0.5 ? .black : .white
        
        DispatchQueue.main.async {
            self.cityLabel.textColor = textColor
            self.dateLabel.textColor = textColor
            self.temperatureLabel.textColor = textColor
            self.weatherDescriptionLabel.textColor = textColor
            self.temperatureUnitButton.setTitleColor(textColor, for: .normal)
            self.locationButton.tintColor = textColor
            
            // Update navigation bar text color
            self.navigationController?.navigationBar.largeTitleTextAttributes = [
                .foregroundColor: textColor
            ]
            self.navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: textColor
            ]
            self.navigationController?.navigationBar.tintColor = textColor
        }
    }
    
    private func createDetailRow(title: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white.withAlphaComponent(0.8)
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textColor = .white
        valueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        cityLabel.isHidden = true
        dateLabel.isHidden = true
        temperatureLabel.isHidden = true
        weatherDescriptionLabel.isHidden = true
        weatherDetailsStackView.isHidden = true
        
        // Ensure the error message is properly constrained
        errorLabel.preferredMaxLayoutWidth = view.bounds.width - 40
    }
    
    private func hideError() {
        errorLabel.isHidden = true
        cityLabel.isHidden = false
        dateLabel.isHidden = false
        temperatureLabel.isHidden = false
        weatherDescriptionLabel.isHidden = false
        weatherDetailsStackView.isHidden = false
    }
    
    // MARK: - Actions
    @objc private func locationButtonTapped() {
        viewModel.selectedCityName = nil
        viewModel.fetchWeatherForCurrentLocation()
    }
    
    @objc private func temperatureUnitButtonTapped() {
        viewModel.toggleTemperatureUnit()
        updateUI(with: viewModel.weatherData)
    }
}

extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            viewModel.clearSearchResults()
            return
        }
        
        // Reduce the delay for better responsiveness
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Clean up the search text
            let cleanedSearchText = searchText.trimmingCharacters(in: .whitespaces)
            
            // Search with the cleaned text
            print("Searching for: \(cleanedSearchText)")
            await viewModel.searchCity(query: cleanedSearchText)
        }
    }
}

