//
//  ViewController.swift
//  Lab8Netoworking
//
//  Created by user236101 on 3/25/24.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var lblWeather: UILabel!
    @IBOutlet weak var lblTemp: UILabel!
    @IBOutlet weak var lblHumidity: UILabel!
    @IBOutlet weak var lblWind: UILabel!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Requesting user's location permission
        locationManager.requestWhenInUseAuthorization()
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Getting location
        guard let userLocation = locations.last else {return}
        
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        
        CLGeocoder().reverseGeocodeLocation(userLocation) {placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            //Setting city in label
            if let city = placemark.locality{
                DispatchQueue.main.async {
                    print(placemark)
                    self.lblLocation.text = "\(city)"
                }
            } else {
                print("City name not found")
            }
        }
        //Function to fetch weather data
        fetchWeatherData(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
    }
    func fetchWeatherData(latitude: Double, longitude: Double) {
        //API
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=04154027bebd9233d8c3f15a13c6abce"
        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
           if let error = error {
                print("Error fetching weather data: \(error.localizedDescription)")
                return
            }
            //Fetching data from Weather JSON data
            if let data = data{
                
                do {
                    let weatherData = try JSONDecoder().decode(Weather.self, from: data)
                    
                    DispatchQueue.main.async {
                        // Update UI elements with weather data
                        self.lblLocation.text = weatherData.name
                        print(weatherData.name)
                        self.lblWeather.text = weatherData.weather[0].description
                        print(weatherData.weather[0].description)
                        //self.lblTemp.text = String(format: "%.2f°C", weatherData.main.temp - 273.15)
                        //print(weatherData.main.temp - 273.15)
                        let temperatureInCelsius = Int(weatherData.main.temp - 273.15)
                        self.lblTemp.text = "\(temperatureInCelsius)°C"
                        print(temperatureInCelsius)
                        self.lblHumidity.text = "Humidity : \(weatherData.main.humidity)%"
                        print(weatherData.main.humidity)
                        //self.lblWind.text = "Wind: \(weatherData.wind.speed)km/h"
                        //print(weatherData.wind.speed)
                        let windSpeedInKMH = Int(weatherData.wind.speed * 3.6)
                        self.lblWind.text = "Wind: \(windSpeedInKMH)km/h"
                        //Fatching icon and setting it in imageview
                        if let iconCode = weatherData.weather.first?.icon {
                            let iconURLString = "https://openweathermap.org/img/w/\(iconCode).png"
                            if let iconURL = URL(string: iconURLString){
                                print(iconURL)
                                URLSession.shared.dataTask(with: iconURL){ data, response, error in
                                    if let error = error{
                                        print("Error fetching image data: \(error)")
                                        return
                                    }
                                    guard let data = data else {
                                        print("No image data received")
                                        return
                                    }
                                    DispatchQueue.main.async {
                                        if let image = UIImage(data: data) {
                                            self.weatherIcon.image = image
                                        } else {
                                            print("Error: Couldn't create image from data")
                                        }
                                    }
                                }.resume()
                            } else {
                                print("Error: Invalid icon URL")
                            }
                        } else {
                            print("Error: Icon code not found")
                        }
                    }
                } catch {
                    print("Error decoding weather data: \(error.localizedDescription)")
                }
            }else {
                print("SOME ERROR FROM SERVER.")
            }
        }
        task.resume()
    
    }
}

