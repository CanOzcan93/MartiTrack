//
//  ViewController.swift
//  MartiTrack
//
//  Created by Can Özcan on 20.11.2024.
//

import UIKit
import MapKit
import SnapKit

class ViewController: UIViewController, ViewModelDelegate {
    
    private lazy var viewModel: ViewModel = {
        let vm = ViewModel()
        vm.delegate = self
        return vm
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private lazy var mapView: MKMapView = {
        let view = MKMapView()
        view.showsUserLocation = TracingManager.shared.isTracing
        view.delegate = self
        if let location = TracingManager.shared.lastLocation {
            view.setRegion(.init(center: location.coordinate, span: .init(latitudeDelta: 0.07, longitudeDelta: 0.07)), animated: false)
        }
        return view
    }()
    
    private lazy var routeResetButton: UIButton = {
        let button = UIButton()
        button.setImage(.init(systemName: "flame.circle.fill"), for: .normal)
        button.addTarget(self, action: #selector(resetRoute), for: .touchUpInside)
        button.tintColor = .systemRed
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    private lazy var playPauseButton: UIButton = {
        let button = UIButton()
        let isTracing = TracingManager.shared.isTracing
        button.setImage(.init(systemName: "play.circle.fill"), for: .normal)
        button.setImage(.init(systemName: "pause.circle.fill"), for: .selected)
        button.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        button.tintColor = isTracing ? .green : .red
        button.isSelected = !isTracing
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configure()
        viewModel.fetchLocations()
        NotificationCenter.default.addObserver(self, selector: #selector(updateMap(_:)), name: NSNotification.Name(rawValue: "tracingManagerDidUpdateLocations"), object: nil)
    }
    
    private func configure() {
        configureView()
        configureConstraints()
    }
    
    private func configureView() {
        view.addSubview(mapView)
        view.addSubview(routeResetButton)
        view.addSubview(playPauseButton)
    }
    
    private func configureConstraints() {
        mapView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        routeResetButton.snp.makeConstraints { make in
            make.leadingMargin.equalToSuperview().offset(50)
            make.bottomMargin.equalToSuperview().offset(-50)
            make.size.equalTo(CGSize(width: 70, height: 70))
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.trailingMargin.bottomMargin.equalToSuperview().offset(-50)
            make.size.equalTo(CGSize(width: 70, height: 70))
        }
    }
    
    @objc private func updateMap(_ notification: Notification) {
        let locations = notification.userInfo?["locations"] as? [CLLocation] ?? []
        viewModel.updateLocations(with: locations)
    }

    
    func locationsUpdated(with newLocations: [CLLocation]) {
        
        mapView.addAnnotations(newLocations.map({
            let annotation = CustomAnnotation()
            annotation.coordinate = $0.coordinate
            viewModel.getAddress(location: $0) { address in
                annotation.title = address
            }
            return annotation
        }))
        
    }
    
    @objc private func resetRoute() {
        viewModel.deleteAllLocations()
        mapView.annotations.forEach({ mapView.removeAnnotation($0) })
    }
    
    @objc private func playPauseButtonTapped(_ sender: UIButton) {
        mapView.showsUserLocation.toggle()
        sender.isSelected.toggle()
        TracingManager.shared.isTracing.toggle()
        
        let isTracking = !sender.isSelected
        playPauseButton.tintColor = isTracking ? .green : .red
        if isTracking {
            TracingManager.shared.startUpdatingLocation()
        } else {
            TracingManager.shared.stopUpdatingLocation()
        }
    }
    
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? CustomAnnotation else { return nil }
        
        var annotationView: MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: "AnID")
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "AnID")
            annotationView.canShowCallout = true
        } else {
            annotationView.annotation = annotation
        }
        
        let rightButton: UIButton = UIButton(type: .detailDisclosure)
        annotationView.rightCalloutAccessoryView = rightButton
        
        if annotation.isCollapsed {
            annotationView.detailCalloutAccessoryView = nil
        } else {
            
            let label: UILabel = UILabel(frame: .init(x: 0, y: 0, width: 200, height: 50))
            label.text = annotation.title
            label.font = .systemFont(ofSize: 14)
            label.numberOfLines = 0
            annotationView.detailCalloutAccessoryView = label
            
            label.widthAnchor.constraint(lessThanOrEqualToConstant: label.frame.width).isActive = true
            label.heightAnchor.constraint(lessThanOrEqualToConstant: 90).isActive = true
            
        }
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        guard let oldAnnotation = view.annotation as? CustomAnnotation else { return }
        
        let annotation: CustomAnnotation = CustomAnnotation()
        annotation.coordinate = oldAnnotation.coordinate
        annotation.title = oldAnnotation.title
        annotation.setNeedsToggle = true
        if oldAnnotation.isCollapsed {
            annotation.isCollapsed = false
        }
        
        mapView.removeAnnotation(oldAnnotation)
        mapView.addAnnotation(annotation)
        
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        views.forEach { view in
            if let annotation = view.annotation as? CustomAnnotation, annotation.setNeedsToggle {
                mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
}

