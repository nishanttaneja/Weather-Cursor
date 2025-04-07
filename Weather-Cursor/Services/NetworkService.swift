import Foundation
import CoreLocation

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return "Server error: \(message)"
        case .apiKeyMissing:
            return "API key is missing. Please add your OpenWeather API key to NetworkService.swift"
        }
    }
}

class NetworkService {
    let apiKey = "YOUR_API_KEY" // Replace with your OpenWeather API key
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let geocodingURL = "https://api.openweathermap.org/geo/1.0"
    
    func fetchWeather(for location: CLLocation) async throws -> WeatherResponse {
        guard apiKey != "YOUR_API_KEY" else {
            throw NetworkError.apiKeyMissing
        }
        
        let urlString = "\(baseURL)/weather?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&units=metric&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    func searchCity(query: String) async throws -> [Location] {
        guard apiKey != "YOUR_API_KEY" else {
            throw NetworkError.apiKeyMissing
        }
        
        // Clean up the query
        let cleanQuery = query.trimmingCharacters(in: .whitespaces)
        guard !cleanQuery.isEmpty else {
            return []
        }
        
        // Try multiple search strategies to get more results
        var allLocations: [Location] = []
        
        // Strategy 1: Direct search with the original query
        let encodedQuery = cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanQuery
        let urlString = "\(geocodingURL)/direct?q=\(encodedQuery)&limit=100&appid=\(apiKey)"
        
        print("Searching for cities with URL: \(urlString)")
        
        if let locations = try? await performSearch(urlString: urlString) {
            allLocations.append(contentsOf: locations)
        }
        
        // Strategy 2: Try with ", India" appended
        let indiaQuery = "\(cleanQuery), India"
        let encodedIndiaQuery = indiaQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? indiaQuery
        let indiaUrlString = "\(geocodingURL)/direct?q=\(encodedIndiaQuery)&limit=100&appid=\(apiKey)"
        
        print("Trying with India appended: \(indiaUrlString)")
        
        if let indiaLocations = try? await performSearch(urlString: indiaUrlString) {
            // Only add locations that aren't already in the results
            let newLocations = indiaLocations.filter { location in
                !allLocations.contains { $0.name == location.name && $0.country == location.country }
            }
            allLocations.append(contentsOf: newLocations)
        }
        
        // Strategy 3: Try with just the first 3 characters
        if cleanQuery.count > 3 {
            let prefixQuery = String(cleanQuery.prefix(3))
            let encodedPrefixQuery = prefixQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? prefixQuery
            let prefixUrlString = "\(geocodingURL)/direct?q=\(encodedPrefixQuery)&limit=100&appid=\(apiKey)"
            
            print("Trying with prefix: \(prefixUrlString)")
            
            if let prefixLocations = try? await performSearch(urlString: prefixUrlString) {
                // Only add locations that aren't already in the results
                let newLocations = prefixLocations.filter { location in
                    !allLocations.contains { $0.name == location.name && $0.country == location.country }
                }
                allLocations.append(contentsOf: newLocations)
            }
        }
        
        // Strategy 4: Try with the reverse geocoding API to get cities by coordinates
        // This is a fallback strategy that might help find more cities
        if allLocations.isEmpty {
            // Try to get a list of major Indian cities as a fallback
            let majorIndianCities = [
                "Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai", 
                "Kolkata", "Pune", "Ahmedabad", "Jaipur", "Lucknow",
                "Kanpur", "Nagpur", "Indore", "Thane", "Bhopal",
                "Visakhapatnam", "Patna", "Vadodara", "Ghaziabad", "Ludhiana"
            ]
            
            // Filter cities that match the query
            let matchingCities = majorIndianCities.filter { 
                $0.lowercased().contains(cleanQuery.lowercased()) 
            }
            
            // Create Location objects for these cities
            for cityName in matchingCities {
                let location = Location(
                    name: cityName,
                    lat: 0, // We don't have coordinates, but we'll fetch them later
                    lon: 0,
                    country: "IN",
                    state: nil
                )
                allLocations.append(location)
            }
        }
        
        print("Found \(allLocations.count) cities in total after all search strategies")
        
        // Sort locations by relevance
        let queryLower = cleanQuery.lowercased()
        allLocations.sort { loc1, loc2 in
            // Exact matches first
            let exactMatch1 = loc1.name.lowercased() == queryLower
            let exactMatch2 = loc2.name.lowercased() == queryLower
            
            if exactMatch1 != exactMatch2 {
                return exactMatch1
            }
            
            // Then check if query is a substring of the city name
            let contains1 = loc1.name.lowercased().contains(queryLower)
            let contains2 = loc2.name.lowercased().contains(queryLower)
            
            if contains1 != contains2 {
                return contains1
            }
            
            // If both contain the query, prioritize those where the query appears at the beginning
            let startsWith1 = loc1.name.lowercased().hasPrefix(queryLower)
            let startsWith2 = loc2.name.lowercased().hasPrefix(queryLower)
            
            if startsWith1 != startsWith2 {
                return startsWith1
            }
            
            // Then by city name length (shorter names first)
            if loc1.name.count != loc2.name.count {
                return loc1.name.count < loc2.name.count
            }
            
            // Finally alphabetically
            return loc1.name < loc2.name
        }
        
        // Print the first few results for debugging
        for (index, location) in allLocations.prefix(5).enumerated() {
            print("Result \(index+1): \(location.name), \(location.country)\(location.state.map { ", \($0)" } ?? "")")
        }
        
        return allLocations
    }
    
    private func performSearch(urlString: String) async throws -> [Location]? {
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let locations = try decoder.decode([Location].self, from: data)
            return locations
        } catch {
            print("Error decoding city search results: \(error)")
            return nil
        }
    }
} 
