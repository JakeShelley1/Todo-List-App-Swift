//
//  AddTaskView.swift
//  Todo
//
//  Created by Jake Shelley on 12/10/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit

protocol AddTaskViewDelegate: class {
    func updateButtonFrame(with keyboardHeight : CGFloat)
    func closeView()
}

class AddTaskView: UIView {

    var primaryColor: UIColor!
    private var kBuffer: CGFloat!
    weak var delegate: AddTaskViewDelegate?
    lazy var textView = UITextView()
    lazy var closeImageView = UIImageView()
    lazy var textLabel = UILabel()
    lazy var titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func build() {
        backgroundColor = .white
        applyDismissKeyboardGesture()
        kBuffer = 15 + (UIScreen.main.bounds.width - MINIMIZED_LIST_WIDTH)/2
        buildUI()
        setConstraints()
        alpha = 0
    }
    
    func setKeyboardObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
    }
    
    func removeKeyboardObserver() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
    }
    
    func showView() {
        textView.becomeFirstResponder()
        textView.text = ""
    }
    
    func hideView() {
        dismissKeyboard()
    }
    
    private func buildUI() {
        titleLabel.text = "New Task"
        titleLabel.font = getPrimaryFont(.medium, size: 16)
        titleLabel.textAlignment = .center
        
        closeImageView.image = UIImage(named: "x")
        closeImageView.tintColor = .lightGray
        closeImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        closeImageView.addGestureRecognizer(tapGesture)
        
        textLabel.text = "What do you need to do?"
        textLabel.font = getPrimaryFont(.medium, size: 15)
        textLabel.textColor = .lightGray
        
        textView.font = getPrimaryFont(.medium, size: 22)
        textView.tintColor = primaryColor
        
        addSubviews([textView, closeImageView, textLabel, titleLabel])
    }
    
    private func setConstraints() {
        closeImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER)
            make.left.equalTo(15)
            make.height.width.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(closeImageView)
            make.height.equalTo(20)
            make.width.equalTo(100)
            make.centerX.equalTo(self)
        }
        
        textLabel.snp.makeConstraints { (make) in
            make.left.equalTo(kBuffer)
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
        }
        
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(textLabel.snp.bottom).offset(10)
            make.left.equalTo(textLabel).offset(-6)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
        }
    }

    // Mark: Keyboard
    
    private func applyDismissKeyboardGesture() {
        let dismissKeyboardGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardGesture.direction = .down
        dismissKeyboardGesture.delegate = self
        self.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            textView.snp.makeConstraints { (make) in
                make.height.equalTo(UIScreen.main.bounds.height - textView.frame.origin.y - keyboardSize.height - 50)
            }
            
            self.layoutIfNeeded()
            delegate?.updateButtonFrame(with: keyboardSize.height)
        }
        
    }
    
    @objc func dismissKeyboard() {
        self.endEditing(true)
        delegate?.closeView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension AddTaskView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
