//
//  PriceRangeSelector.swift
//  DateRangeSelector
//
//  Created by Ihor Povzyk on 29.01.2025.
//

import Foundation
import SwiftUI
import UIKit

struct DateRange: Equatable {
    let start: Date
    let end: Date
}

protocol DateRangePickerDelegate: AnyObject {
    func didChangeDates(range: DateRange)
}

class DateRangePicker: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    private let startDateLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    private let endDateLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    private lazy var startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        if let sixMonthsLater = Calendar.current.date(byAdding: .month, value: 6, to: Date()) {
            picker.maximumDate = sixMonthsLater
        }
        
        picker.tintColor = .gray
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(self, action: #selector(startDateChanged(_:)), for: .valueChanged)
        return picker
    }()
    
    private lazy var endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.minimumDate = Date()
        if let sixMonthsLater = Calendar.current.date(byAdding: .month, value: 6, to: Date()) {
            picker.maximumDate = viewState?.maxSelectableDate ?? sixMonthsLater
        }

        picker.tintColor = .gray
        picker.preferredDatePickerStyle = .compact
        picker.addTarget(self, action: #selector(endDateChanged(_:)), for: .valueChanged)
        return picker
    }()
    
    private var viewState: ViewState? {
        didSet {
            guard let viewState else {
                return
            }
            
            titleLabel.text = viewState.title
            startDateLabel.text = viewState.startDate
            endDateLabel.text = viewState.endDate
            
            if let preselectedRange = viewState.preselectedRange {
                startDatePicker.date = preselectedRange.start
                endDatePicker.date = preselectedRange.end
            }
        }
    }

    weak var delegate: DateRangePickerDelegate?
    var completion: ((DateRange) -> Void)?
    
    private(set) var selectedStartDate: Date = Date()
    private(set) var selectedEndDate: Date = Date()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    func render(_ viewState: ViewState) {
        self.viewState = viewState
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(startDateLabel)
        addSubview(startDatePicker)
        addSubview(endDateLabel)
        addSubview(endDatePicker)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        startDateLabel.translatesAutoresizingMaskIntoConstraints = false
        startDatePicker.translatesAutoresizingMaskIntoConstraints = false
        endDateLabel.translatesAutoresizingMaskIntoConstraints = false
        endDatePicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            
            startDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            startDateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            
            startDatePicker.centerYAnchor.constraint(equalTo: startDateLabel.centerYAnchor),
            startDatePicker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            endDateLabel.topAnchor.constraint(equalTo: startDateLabel.bottomAnchor, constant: 20),
            endDateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            
            endDatePicker.centerYAnchor.constraint(equalTo: endDateLabel.centerYAnchor),
            endDatePicker.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    @objc private func startDateChanged(_ sender: UIDatePicker) {
        selectedStartDate = sender.date
        
        // Update the minimum date of the endDatePicker to ensure it's the same or later than the start date
        endDatePicker.minimumDate = selectedStartDate
        
        // Adjust end date if it's earlier than the new start date
        if selectedEndDate < selectedStartDate {
            endDatePicker.date = selectedStartDate
            selectedEndDate = selectedStartDate
        }
        
        delegate?.didChangeDates(range: .init(start: selectedStartDate, end: selectedEndDate))
    }
    
    @objc private func endDateChanged(_ sender: UIDatePicker) {
        selectedEndDate = sender.date
        
        // Ensure end date is not earlier than start date
        if selectedEndDate < selectedStartDate {
            sender.date = selectedStartDate
            selectedEndDate = selectedStartDate
        }
        
        completion?(.init(start: selectedStartDate, end: selectedEndDate))
        delegate?.didChangeDates(range: .init(start: selectedStartDate, end: selectedEndDate))
    }
}

extension DateRangePicker {
    struct ViewState {
        let title: String
        let startDate: String
        let endDate: String
        let maxSelectableDate: Date // default to 6 months from now
        let preselectedRange: DateRange?
    }
}

struct DateRangePickerUIKit: UIViewRepresentable {
    private let viewState: DateRangePicker.ViewState
    
    private weak var delegate: DateRangePickerDelegate?
    
    init(
        viewState: DateRangePicker.ViewState,
        delegate: DateRangePickerDelegate?
    ) {
        self.viewState = viewState
        self.delegate = delegate
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = DateRangePicker()
        view.render(viewState)
        view.completion = { range in
            delegate?.didChangeDates(range: range)
        }
        
        return view
    }

    // Update the UIKit view if SwiftUI needs to redraw it
    func updateUIView(_ uiView: UIView, context: Context) {
        // Handle updates to the view
    }
}
