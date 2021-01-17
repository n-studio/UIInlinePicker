//
//  UIInlinePicker.swift
//  UIInlinePicker
//
//  Created by Matthew Nguyen on 30/12/2020.
//

import UIKit

public enum UIInlinePickerMode {
    case time
    case duration
    case number
    case custom
}

public enum UIInlinePickerTimePrecision {
    case hourMinute
    case hourMinuteSecond
    case hourMinuteSecondMillisecondPer500
    case hourMinuteSecondMillisecond
    case minuteSecond
    case minuteSecondMillisecondPer500
    case minuteSecondMillisecond
}

public enum UIInlinePickerDigitGrouping {
    case integer // 9999
    case decimal // 9999.99
    case thousand // 999,999,999
    case thousandDecimal // 999,999.99
    case myriad // 9999,9999,9999
    case myriadDecimal // 9999,9999.99
}

public protocol UIInlinePickerDelegate {
    func pickerView(_ pickerView: UIPickerView, didUpdateCustomEntry customEntry: String)
}

fileprivate class PaddedLabel: UILabel {
    var insets: UIEdgeInsets

    required init(withInsets insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: self.insets))
    }

    override var intrinsicContentSize: CGSize {
        get {
            var contentSize = super.intrinsicContentSize
            contentSize.height += insets.top + insets.bottom
            contentSize.width += insets.left + insets.right
            return contentSize
        }
    }
}

open class UIInlinePicker: UIControl {
    internal var isSelecting: Bool = false
    internal var textField = UITextField()
    public var pickerView: UIPickerView = UIPickerView()
    internal var separators: [UILabel] = []
    open var inlineDelegate: UIInlinePickerDelegate?
    open var delegate: UIPickerViewDelegate?
    open var dataSource: UIPickerViewDataSource?
    open var mode: UIInlinePickerMode = .time {
        didSet {
            if [.duration, .number, .time].contains(self.mode) {
                self.keyboardType = .numberPad
            }
            self.pickerView.reloadAllComponents()
        }
    }
    open var timePrecision: UIInlinePickerTimePrecision = .hourMinute {
        didSet {
            if [.minuteSecondMillisecond, .hourMinuteSecondMillisecondPer500, .minuteSecondMillisecond, .minuteSecondMillisecondPer500].contains(self.timePrecision) {
                self.keyboardType = .numberPad
                self.decimalPrecision = 3
            }
            self.pickerView.reloadAllComponents()
        }
    }
    open var digitGrouping: UIInlinePickerDigitGrouping = .integer {
        didSet {
            self.pickerView.reloadAllComponents()
        }
    }
    open var numberPrecision: Int = 6
    open var decimalPrecision: Int = 2
    open var prefix: String = ""
    open var suffix: String = ""
    open var separator: String?
    open var decimalSeparator: String?
    internal var _separator: String {
        get {
            if let separator = separator {
                return separator
            }
            switch self.mode {
            case .time, .duration:
                return ":"
            case .number:
                return ","
            case .custom:
                return ""
            }
        }
    }
    internal var _decimalSeparator: String {
        get {
            if let decimalSeparator = separator {
                return decimalSeparator
            }
            switch self.mode {
            case .time, .duration:
                return ":"
            case .number:
                return "."
            case .custom:
                return ""
            }
        }
    }

    open var text: String? {
        get {
            if self.textField.text != "" {
                return self.textField.text
            }
            return textFromPickerView(self.pickerView)
        }
        set {
            self.textField.text = newValue
        }
    }
    open var font: UIFont = UIFont.systemFont(ofSize: 20)
    open var textColor: UIColor = .label {
        didSet {
            self.pickerView.tintColor = self.textColor
        }
    }
    open var keyboardType: UIKeyboardType = .default {
        didSet {
            self.textField.keyboardType = self.keyboardType
        }
    }
    open var borderColor: UIColor = .clear {
        didSet {
            self.layer.borderColor = self.borderColor.cgColor
        }
    }
    open var borderWidth: CGFloat = 1.5 {
        didSet {
            self.layer.borderWidth = self.borderWidth
        }
    }
    open var cornerRadius: CGFloat = 8 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
        }
    }
    open var adjustsFontSizeToFitWidth: Bool = false

    open func reloadData() {
        guard let text = self.textField.text else { return }
        if [.duration, .number, .time].contains(self.mode) {
            self.textField.text = self.textField.text?.filter("0123456789".contains)
        }
        selectRows(self.pickerView, withValue: text, animated: false)
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)

        setupView()
    }

    internal func setupView() {
        self.backgroundColor = .systemGroupedBackground
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = self.borderWidth
        self.layer.borderColor = self.borderColor.cgColor

        self.textField.frame = CGRect(x: -1000, y: 0, width: 1, height: 1)
        self.textField.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(self.textField)
        self.textField.delegate = self
        self.textField.addTarget(self, action: #selector(textDidBegin), for: .editingDidBegin)
        self.textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)

        self.pickerView.frame = CGRect(x: -10, y: -10, width: self.bounds.size.width + 20, height: self.bounds.size.height + 20)
        self.pickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.pickerView.backgroundColor = .clear
        self.pickerView.tintColor = .clear
        self.addSubview(self.pickerView)
        self.pickerView.dataSource = self
        self.pickerView.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.delegate = self
        self.pickerView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.pickerView.addGestureRecognizer(panGesture)

        updateView()
    }

    internal func updateView() {
        self.textField.keyboardType = self.keyboardType
    }

    @objc internal func textDidBegin() {
        self.textField.text = ""
    }

    @objc internal func textDidChange() {
        guard let text = self.textField.text else { return }
        reloadData()
        self.inlineDelegate?.pickerView(self.pickerView, didUpdateCustomEntry: text)
        self.sendActions(for: .valueChanged)
        self.sendActions(for: .editingChanged)
        self.selectRows(self.pickerView, withValue: text, animated: false)
    }

    @objc internal func handleTap() {
        self.textField.becomeFirstResponder()
    }

    @objc internal func handlePan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.isSelecting = true
            self.layer.borderColor = self.tintColor.cgColor
            for separator in self.separators {
                separator.textColor = tintColor
            }
            self.pickerView.reloadAllComponents()
        case .ended, .cancelled:
            self.isSelecting = self.textField.isFirstResponder
            if !self.isSelecting {
                self.layer.borderColor = self.borderColor.cgColor
                for separator in self.separators {
                    separator.textColor = self.textColor
                }
                self.pickerView.reloadAllComponents()
            }
        default:
            ()
        }
    }

    internal func updateSeparators(count: Int) {
        for separator in self.separators {
            separator.removeFromSuperview()
        }
        self.separators = []
        let separatorsCount = count - 1
        if separatorsCount <= 0 {
            return
        }
        let width = (self.bounds.size.width - 8) / CGFloat(separatorsCount + 1)
        for i in 0..<separatorsCount {
            let separator = UILabel(frame: CGRect(x: 7 + width * CGFloat(i), y: -1, width: width, height: self.bounds.size.height))
            separator.text = (i == separatorsCount - 1) ? self._decimalSeparator : self._separator
            separator.font = self.font
            separator.textAlignment = .right
            separator.isUserInteractionEnabled = false
            addSubview(separator)
            self.separators.append(separator)
        }
    }

    internal func selectRows(_ pickerView: UIPickerView, withValue value: String, animated: Bool) {
        let numberOfRows = self.pickerView(pickerView, numberOfRowsInComponent: 0)
        switch self.mode {
        case .custom:
            for row in 0..<numberOfRows {
                if value == self.titleForRow(row, forComponent: 0) {
                    pickerView.selectRow(row, inComponent: 0, animated: animated)
                    return
                }
            }
        default:
            let componentsCount = self.numberOfComponents(in: pickerView)

            for component in 0..<componentsCount {
                let value = partialValueForComponent(component, fromValue: value)
                pickerView.selectRow(value, inComponent: component, animated: animated)
            }
        }
    }

    internal func partialValueForComponent(_ component: Int, fromValue value: String) -> Int {
        let componentsCount = self.numberOfComponents(in: self.pickerView)
        let integerValue = Int(value) ?? 0
        let groupingSize: Int
        let decimal: Bool

        switch self.mode {
        case .duration, .time:
            switch self.timePrecision {
            case .hourMinuteSecondMillisecond, .hourMinuteSecondMillisecondPer500, .minuteSecondMillisecond, .minuteSecondMillisecondPer500:
                decimal = true
            default:
                decimal = false
            }
            groupingSize = 2
        case .number:
            switch self.digitGrouping {
            case .integer, .decimal:
                groupingSize = self.numberPrecision
            case .thousand, .thousandDecimal:
                groupingSize = 3
            case .myriad, .myriadDecimal:
                groupingSize = 4
            }

            switch self.digitGrouping {
            case .integer, .thousand, .myriad:
                decimal = false
            case .decimal, .thousandDecimal, .myriadDecimal:
                decimal = true
            }
        default:
            return 0
        }

        let power: Int
        let powerPlusOne: Int
        if decimal {
            if component == componentsCount - 1 {
                power = 1
            }
            else {
                power = Int(pow(Double(10), Double((componentsCount - component - 2) * groupingSize + self.decimalPrecision)))
            }
            powerPlusOne = Int(pow(Double(10), Double((componentsCount - component - 1) * groupingSize + self.decimalPrecision)))
        }
        else {
            power = Int(pow(Double(10), Double((componentsCount - component - 1) * groupingSize)))
            powerPlusOne = Int(pow(Double(10), Double((componentsCount - component) * groupingSize)))
        }

        return integerValue / power % (powerPlusOne / power)
    }
}

extension UIInlinePicker: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.isKind(of: UITapGestureRecognizer.self) && gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            return true
        }
        return false
    }
}

extension UIInlinePicker: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
        self.layer.borderColor = self.tintColor.cgColor
        for separator in self.separators {
            separator.textColor = self.tintColor
        }
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.isSelecting = false
        self.layer.borderColor = self.borderColor.cgColor
        for separator in self.separators {
            separator.textColor = self.textColor
        }
        self.pickerView.reloadAllComponents()
    }
}

extension UIInlinePicker: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        let count: Int
        switch self.mode {
        case .custom:
            count = 1
        case .time, .duration:
            switch self.timePrecision {
            case .hourMinute:
                count = 2
            case .hourMinuteSecond:
                count = 3
            case .hourMinuteSecondMillisecondPer500:
                count = 4
            case .hourMinuteSecondMillisecond:
                count = 4
            case .minuteSecond:
                count = 2
            case .minuteSecondMillisecondPer500:
                count = 3
            case .minuteSecondMillisecond:
                count = 3
            }
        case .number:
            switch self.digitGrouping {
            case .integer:
                count = 1
            case .decimal:
                count = 2
            case .thousand:
                count = 3
            case .thousandDecimal:
                count = 3
            case .myriad:
                count = 3
            case .myriadDecimal:
                count = 3
            }
        }
        if self.separators.count != count {
            updateSeparators(count: count)
        }
        return count
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch self.mode {
        case .custom:
            return self.dataSource?.pickerView(pickerView, numberOfRowsInComponent: component) ?? 0
        case .time, .duration:
            switch self.timePrecision {
            case .hourMinute, .hourMinuteSecond, .hourMinuteSecondMillisecond, .hourMinuteSecondMillisecondPer500:
                switch component {
                case 0:
                    return 24
                case 1:
                    return 60
                case 2:
                    return 60
                default:
                    return self.timePrecision == .hourMinuteSecondMillisecond ? 1000 : 2
                }
            case .minuteSecond, .minuteSecondMillisecond, .minuteSecondMillisecondPer500:
                switch component {
                case 0:
                    return 60
                case 1:
                    return 60
                default:
                    return self.timePrecision == .minuteSecondMillisecond ? 1000 : 2
                }
            }
        case .number:
            let componentsCount = self.numberOfComponents(in: self.pickerView)
            switch self.digitGrouping {
            case .integer:
                return Int(pow(Double(10), Double(self.numberPrecision)))
            case .decimal:
                if component == componentsCount - 1 {
                    return Int(pow(Double(10), Double(self.decimalPrecision)))
                }
                else {
                    return Int(pow(Double(10), Double(self.numberPrecision)))
                }
            case .thousand:
                return Int(pow(Double(10), Double(3)))
            case .thousandDecimal:
                if component == componentsCount - 1 {
                    return Int(pow(Double(10), Double(self.decimalPrecision)))
                }
                else {
                    return Int(pow(Double(10), Double(3)))
                }
            case .myriad:
                return Int(pow(Double(10), Double(4)))
            case .myriadDecimal:
                if component == componentsCount - 1 {
                    return Int(pow(Double(10), Double(self.decimalPrecision)))
                }
                else {
                    return Int(pow(Double(10), Double(4)))
                }
            }
        }
    }
}

extension UIInlinePicker: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        pickerView.subviews.last?.isHidden = true
        let leftPadding: CGFloat = component == 0 ? 4 : 0
        let rightPadding: CGFloat = component == pickerView.numberOfComponents - 1 ? 4 : 0
        let label = PaddedLabel(withInsets: UIEdgeInsets(top: 0, left: leftPadding, bottom: 0, right: rightPadding))
        label.adjustsFontSizeToFitWidth = self.adjustsFontSizeToFitWidth
        label.font = self.font
        if component == 0 && component != pickerView.numberOfComponents - 1 {
            label.textAlignment = .right
        }
        else if component != 0 && component == pickerView.numberOfComponents - 1 {
            label.textAlignment = .left
        }
        else {
            label.textAlignment = .center
        }

        label.text = titleForRow(row, forComponent: component)

        label.textColor = (self.textField.isEditing || self.isSelecting) ? self.tintColor : self.textColor
        return label
    }

    public func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return self.bounds.size.width / CGFloat(self.numberOfComponents(in: pickerView) )
    }

    public func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return self.bounds.height + [font.pointSize - 36.5, CGFloat(-17)].max()!
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.textField.text = ""
        self.sendActions(for: .valueChanged)
        self.sendActions(for: .editingChanged)
    }

    internal func textFromPickerView(_ pickerView: UIPickerView) -> String? {
        var titles: [String] = []
        for component in 0..<pickerView.numberOfComponents {
            titles.append(titleForRow(pickerView.selectedRow(inComponent: component), forComponent: component) ?? "")
        }
        switch self.digitGrouping {
        case .integer, .thousand, .myriad:
            return titles.joined(separator: self._separator)
        case .decimal, .thousandDecimal, .myriadDecimal:
            let lastElement = titles.removeLast()
            return [titles.joined(separator: self._separator), lastElement].joined(separator: self._decimalSeparator)
        }
    }

    internal func titleForRow(_ row: Int, forComponent component: Int) -> String? {
        switch self.mode {
        case .time, .duration:
            let length: Int
            switch self.timePrecision {
            case .hourMinuteSecondMillisecond, .hourMinuteSecondMillisecondPer500:
                switch component {
                case 0:
                    length = 1
                case 3:
                    length = 3
                default:
                    length = 2
                }
            case .minuteSecondMillisecond, .minuteSecondMillisecondPer500:
                switch component {
                case 0:
                    length = 1
                case 2:
                    length = 3
                default:
                    length = 2
                }
            default:
                length = component == 0 ? 1 : 2
            }
            if self.timePrecision == .hourMinuteSecondMillisecondPer500 && component == 3 {
                return String(format: "%0\(length)d", row == 0 ? 0 : 500)
            }
            else if self.timePrecision == .minuteSecondMillisecondPer500 && component == 2 {
                return String(format: "%0\(length)d", row == 0 ? 0 : 500)
            }
            else {
                return String(format: "%0\(length)d", row)
            }
        case .number:
            let length: Int
            if component == 0 {
                length = 0
            }
            else {
                if component == self.numberOfComponents(in: self.pickerView) - 1 {
                    length = self.decimalPrecision
                }
                else {
                    switch self.digitGrouping {
                    case .decimal, .integer:
                        length = 1
                    case .thousand, .thousandDecimal:
                        length = 3
                    case .myriad, .myriadDecimal:
                        length = 4
                    }
                }
            }
            if component == 0 {
                return String(format: "\(prefix)%0\(length)d", row)
            }
            else if component == self.numberOfComponents(in: self.pickerView) - 1 {
                return String(format: "%0\(length)d\(suffix)", row)
            }
            else {
                return String(format: "%0\(length)d", row)
            }
        case .custom:
            return self.delegate?.pickerView?(self.pickerView, titleForRow: row, forComponent: component)
        }
    }
}
