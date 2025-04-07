import Foundation

struct WeatherResponse: Codable {
    let weather: [Weather]
    let main: MainWeather
    let wind: Wind
    let name: String
    let sys: Sys
    let visibility: Int
    let dt: TimeInterval
    let timezone: Int
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let humidity: Int
        let pressure: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case tempMin = "temp_min"
            case tempMax = "temp_max"
            case humidity
            case pressure
        }
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int
        
        var direction: String {
            let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
            let index = Int((Double(deg) / 22.5).rounded()) % 16
            return directions[index]
        }
    }
    
    struct Sys: Codable {
        let country: String
        let sunrise: TimeInterval
        let sunset: TimeInterval
    }
    
    // Computed properties for formatted data
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: dt)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
    
    var sunriseTime: String {
        let date = Date(timeIntervalSince1970: sys.sunrise)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    var sunsetTime: String {
        let date = Date(timeIntervalSince1970: sys.sunset)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct Location: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
} 