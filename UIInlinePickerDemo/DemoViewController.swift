//
//  DemoViewController.swift
//  UIInlinePickerDemo
//
//  Created by Matthew Nguyen on 31/12/2020.
//

import UIKit

class DemoViewController: UIViewController {
    let customOriginalChoices = [
        "24mm",
        "35mm",
        "40mm",
        "50mm",
        "70mm"
    ]

    var customChoices: [String] = []

    var twoColumnChoicesLeft: [String] = []
    var twoColumnChoicesRight: [String] = []

    var threeColumnChoicesLeft: [String] = []
    var threeColumnChoicesMiddle: [String] = []
    var threeColumnChoicesRight: [String] = []

    var customInlinePicker: UIInlinePicker?
    var customResultLabel: UILabel?

    var durationInlinePicker: UIInlinePicker?
    var durationResultLabel: UILabel?

    var moneyInlinePicker: UIInlinePicker?
    var moneyResultLabel: UILabel?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.customChoices = customOriginalChoices

        // custom

        self.customInlinePicker = UIInlinePicker(frame: CGRect(x: 10, y: 64, width: 100, height: 34))
        self.customInlinePicker?.accessibilityIdentifier = "customInlinePicker"
        self.customInlinePicker?.accessibilityLabel = "customInlinePicker"
        self.customInlinePicker?.font = UIFont.systemFont(ofSize: 12)
        self.customInlinePicker?.mode = .custom
        self.customInlinePicker?.dataSource = self
        self.customInlinePicker?.delegate = self
        self.customInlinePicker?.inlineDelegate = self
        self.view.addSubview(self.customInlinePicker!)
        self.customInlinePicker?.addTarget(self, action: #selector(inlinePickerValueDidChange), for: .valueChanged)

        self.customResultLabel = UILabel(frame: CGRect(x: 10, y: 100, width: 100, height: 34))
        self.customResultLabel?.text = "result"
        self.view.addSubview(self.customResultLabel!)

        // duration

        self.durationInlinePicker = UIInlinePicker(frame: CGRect(x: 10, y: 164, width: 140, height: 34))
        self.durationInlinePicker?.font = UIFont.systemFont(ofSize: 20)
        self.durationInlinePicker?.mode = .time
        self.durationInlinePicker?.timePrecision = .minuteSecondMillisecondPer500
        self.durationInlinePicker?.dataSource = self
        self.durationInlinePicker?.delegate = self
        self.durationInlinePicker?.inlineDelegate = self
        self.view.addSubview(self.durationInlinePicker!)
        self.durationInlinePicker?.addTarget(self, action: #selector(inlinePickerValueDidChange(_:)), for: .valueChanged)

        self.durationResultLabel = UILabel(frame: CGRect(x: 10, y: 200, width: 100, height: 34))
        self.durationResultLabel?.text = "result"
        self.view.addSubview(self.durationResultLabel!)

        // money

        self.moneyInlinePicker = UIInlinePicker(frame: CGRect(x: 10, y: 264, width: 140, height: 34))
        self.moneyInlinePicker?.font = UIFont.systemFont(ofSize: 14)
        self.moneyInlinePicker?.mode = .number
        self.moneyInlinePicker?.digitGrouping = .myriadDecimal
        self.moneyInlinePicker?.numberPrecision = 6
        self.moneyInlinePicker?.decimalPrecision = 2
        self.moneyInlinePicker?.prefix = "$"
        self.moneyInlinePicker?.dataSource = self
        self.moneyInlinePicker?.delegate = self
        self.moneyInlinePicker?.inlineDelegate = self
        self.view.addSubview(self.moneyInlinePicker!)
        self.moneyInlinePicker?.addTarget(self, action: #selector(inlinePickerValueDidChange(_:)), for: .valueChanged)

        self.moneyResultLabel = UILabel(frame: CGRect(x: 10, y: 300, width: 200, height: 34))
        self.moneyResultLabel?.text = "result"
        self.view.addSubview(self.moneyResultLabel!)

        let datePicker = UIDatePicker(frame: CGRect(x: 10, y: 340, width: 100, height: 34))
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .time
        self.view.addSubview(datePicker)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.durationInlinePicker?.text = "1230000"
    }

    @objc func inlinePickerValueDidChange(_ sender: UIInlinePicker) {
        switch(sender) {
        case self.customInlinePicker:
            self.customResultLabel?.text = self.customInlinePicker?.text
        case self.durationInlinePicker:
            self.durationResultLabel?.text = self.durationInlinePicker?.text
        case self.moneyInlinePicker:
            self.moneyResultLabel?.text = self.moneyInlinePicker?.text
        default:
            ()
        }
    }
}

extension DemoViewController: UIInlinePickerDelegate {
    func pickerView(_ pickerView: UIPickerView, didUpdateCustomEntry customEntry: String) {
        switch(pickerView) {
        case self.customInlinePicker?.pickerView:
            if !self.customOriginalChoices.contains(customEntry) {
                self.customChoices = self.customOriginalChoices
                self.customChoices.append(customEntry)
                pickerView.reloadAllComponents()
            }
        default:
            ()
        }
    }
}

extension DemoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        switch(pickerView) {
        case self.customInlinePicker?.pickerView:
            return 1
        default:
            fatalError()
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch(pickerView) {
        case self.customInlinePicker?.pickerView:
            return customChoices.count
        default:
            fatalError()
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch(pickerView) {
        case self.customInlinePicker?.pickerView:
            return customChoices[row]
        default:
            fatalError()
        }
    }
}
