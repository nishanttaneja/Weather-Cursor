import Foundation
import CoreLocation
import Combine

enum TemperatureUnit: String, CaseIterable {
    case celsius = "C"
    case fahrenheit = "F"
    
    var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
    
    func convert(_ celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return (celsius * 9/5) + 32
        }
    }
}

@MainActor
class WeatherViewModel: NSObject, ObservableObject {
    private let networkService: NetworkService
    private let locationManager: CLLocationManager
    
    @Published var weatherData: WeatherResponse?
    @Published var searchResults: [Location] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var temperatureUnit: TemperatureUnit = .celsius
    @Published var selectedCityName: String?
    
    override init() {
        self.networkService = NetworkService()
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        
        // Load saved temperature unit preference
        if let savedUnit = UserDefaults.standard.string(forKey: "temperatureUnit"),
           let unit = TemperatureUnit(rawValue: savedUnit) {
            self.temperatureUnit = unit
        }
    }
    
    func toggleTemperatureUnit() {
        temperatureUnit = temperatureUnit == .celsius ? .fahrenheit : .celsius
        // Save preference
        UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
    }
    
    func getTemperatureString(_ celsius: Double) -> String {
        let convertedTemp = temperatureUnit.convert(celsius)
        return String(format: "%.1f°%@", convertedTemp, temperatureUnit.rawValue)
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func fetchWeatherForCurrentLocation() {
        guard let location = locationManager.location else {
            errorMessage = "Unable to get current location. Please check your location settings."
            return
        }
        
        Task {
            await fetchWeather(for: location)
        }
    }
    
    @MainActor
    func searchCity(query: String) async {
        isLoading = true
        searchResults = []
        
        do {
            var locations = try await networkService.searchCity(query: query)
            
            // For any locations without coordinates, try to fetch them
            for i in 0..<locations.count {
                if locations[i].lat == 0 && locations[i].lon == 0 {
                    // Try to get coordinates for this city
                    if let coordinates = try? await fetchCoordinatesForCity(locations[i].name, country: locations[i].country) {
                        locations[i] = Location(
                            name: locations[i].name,
                            lat: coordinates.latitude,
                            lon: coordinates.longitude,
                            country: locations[i].country,
                            state: locations[i].state
                        )
                    }
                }
            }
            
            searchResults = locations
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchCoordinatesForCity(_ cityName: String, country: String) async throws -> CLLocationCoordinate2D? {
        let query = "\(cityName), \(country)"
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://api.openweathermap.org/geo/1.0/direct?q=\(encodedQuery)&limit=1&appid=\(networkService.apiKey)"
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        do {
            let decoder = JSONDecoder()
            let locations = try decoder.decode([Location].self, from: data)
            
            if let location = locations.first {
                return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
            }
        } catch {
            print("Error fetching coordinates for \(cityName): \(error)")
        }
        
        return nil
    }
    
    func clearSearchResults() {
        searchResults = []
    }
    
    @MainActor
    func fetchWeather(for location: CLLocation, cityName: String? = nil) async {
        do {
            isLoading = true
            errorMessage = nil
            
            // Store the selected city name if provided
            if let cityName = cityName {
                selectedCityName = cityName
            }
            
            weatherData = try await networkService.fetchWeather(for: location)
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func getBackgroundImageName() -> String {
        guard let weather = weatherData?.weather.first else { 
            print("No weather data available, using default background")
            return "default_background" 
        }
        
        print("Weather condition: \(weather.main), description: \(weather.description)")
        
        switch weather.main.lowercased() {
        case "clear":
            return "clear_background"
        case "clouds":
            return "cloudy_background"
        case "rain":
            return "rain_background"
        case "snow":
            return "snow_background"
        case "thunderstorm":
            return "thunder_background"
        default:
            print("Unknown weather condition: \(weather.main), using default background")
            return "default_background"
        }
    }
}

extension WeatherViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable location services in Settings to get weather for your current location."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task {
            await fetchWeather(for: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Location error: \(error.localizedDescription)"
    }
} 