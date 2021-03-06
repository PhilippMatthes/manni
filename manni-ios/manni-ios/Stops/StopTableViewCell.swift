//
//  StopTableViewCell.swift
//  manni-ios
//
//  Created by yaaarrrnnn on 02.02.20.
//  Copyright © 2020 Philipp Matthes. All rights reserved.
//

import Material
import DVB
import CoreLocation


class StopTableViewCell: UITableViewCell {
    fileprivate let skeuomorphismView = SkeuomorphismView()
    fileprivate let stopNameLabel = UILabel()
    fileprivate let stopLocationLabel = UILabel()
    
    public static let reuseIdentifier = "StopTableViewCell"
    
    public var stop: Stop? {
        didSet {
            if let stop = stop {
                stopNameLabel.text = stop.name
                stopLocationLabel.text = stop.region ?? "Dresden"
                skeuomorphismView.contentView.isLoading = false
            } else {
                stopNameLabel.text = " "
                stopLocationLabel.text = " "
                skeuomorphismView.contentView.isLoading = true
            }
        }
    }
    
    public var location: CLLocation? {
        didSet {
            if let location = location, let distance = stop?.approximateDistance(from: location) {
                let distanceStr = distance > 1000 ? "\(distance / 1000) km" : "\(distance) m"
                stopLocationLabel.text = "\(distanceStr) entfernt, in \(stop?.region ?? "Dresden")"
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepare()
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        prepare()
    }
    
    func prepare() {
        stopNameLabel.text = "Lade Haltestelle..."
        stopLocationLabel.text = "Lade Ort..."
        
        selectionStyle = .none
        backgroundColor = .clear
        layer.cornerRadius = 24
        
        contentView.layout(skeuomorphismView)
            .edges(top: 16, left: 12, bottom: 12, right: 12)
        skeuomorphismView.contentView.backgroundColor = Color.grey.lighten4
        skeuomorphismView.lightShadowOpacity = 1
        skeuomorphismView.darkShadowOpacity = 0.07
        skeuomorphismView.cornerRadius = 16
        
        contentView.layout(stopNameLabel)
            .top(32)
            .left(32)
            .right(32)
        stopNameLabel.font = RobotoFont.bold(with: 24)
        stopNameLabel.textColor = Color.grey.darken4
        stopNameLabel.numberOfLines = 0
        stopNameLabel.layer.cornerRadius = 8
        stopNameLabel.clipsToBounds = true
        
        contentView.layout(stopLocationLabel)
            .below(stopNameLabel, 8)
            .left(32)
            .right(32)
            .bottom(32)
        stopLocationLabel.font = RobotoFont.light(with: 18)
        stopLocationLabel.textColor = Color.grey.darken2
        stopLocationLabel.numberOfLines = 0
        stopLocationLabel.layer.cornerRadius = 8
        stopLocationLabel.clipsToBounds = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLocation(_:)), name: SearchController.didUpdateLocation, object: nil)
        
        skeuomorphismView.contentView.fakedViews = [stopNameLabel, stopLocationLabel]
    }
    
    @objc func didUpdateLocation(_ notification: Notification) {
        guard
            let data = notification.userInfo as? [String: CLLocation],
            let location = data["location"]
        else {return}
        self.location = location
    }
    
}
