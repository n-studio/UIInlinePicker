# UIInlinePicker

Customizable UIControl that replicates inline UIDatePicker.

## Usage

See `UIInlinePickerDemo/DemoViewController.swift`.

```swift
inlinePicker = UIInlinePicker(frame: CGRect(x: 10, y: 44, width: 100, height: 34))
inlinePicker.font = UIFont.systemFont(ofSize: 12)
inlinePicker.mode = .custom
inlinePicker.dataSource = self
inlinePicker.delegate = self
self.view.addSubview(inlinePicker)
inlinePicker.addTarget(self, action: #selector(inlinePickerValueDidChange), for: .valueChanged)
```

## Known issues:

* `UIInlinePicker` is not compatible with Apple Pencil scribble. We would like to add support for it but so far we couldn't find a proper way to do it. Feel free to submit a PR if you found a way to make it compatible.
* It's not possible yet to select only one component.
* Selecting the picker won't show the text color as selected
* Clicking outside the field won't make it resign as first responder
