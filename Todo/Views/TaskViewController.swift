//
//  TaskViewController.swift
//  Todo
//
//  Created by Jake Shelley on 12/13/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit
import SnapKit
import RealmSwift

protocol TaskViewControllerDelegate: class {
    func dismissDetailView(deletedActiveTask: Bool)
}

class TaskViewController: UIViewController {
    
    var task: Task!
    var taskList: TaskList!
    var completed: Bool!
    var taskTextViewHeightConstraint: Constraint!
    var noteTextViewHeightConstraint: Constraint!
    private var keyboardIsShown = false
    private var savedYValue:CGFloat = 0
    private var dismissKeyboardSwipe: UISwipeGestureRecognizer!
    lazy var closeImageView = UIImageView()
    lazy var trashImageView = UIImageView()
    lazy var taskTextView = UITextView()
    lazy var noteTextView = UITextView()
    lazy var statusLabel = UILabel()
    lazy var noteLabel = UILabel()
    lazy var divider = UIView()
    lazy var scrollView = UIScrollView()
    lazy var textViewPlaceholder = UILabel()
    weak var delegate: TaskViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyDismissKeyboardGesture()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        buildUI()
        setConstraints()
    }
    
    private func buildUI() {
        view.backgroundColor = .white
        
        scrollView.alwaysBounceVertical = true
        scrollView.delegate = self
        
        closeImageView.image = UIImage(named: "x")
        closeImageView.tintColor = .lightGray
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(closeView))
        closeImageView.addGestureRecognizer(closeTap)
        closeImageView.isUserInteractionEnabled = true
        
        trashImageView.image = UIImage(named: "trash")
        trashImageView.tintColor = .redOrange
        trashImageView.isUserInteractionEnabled = true
        let deleteTap = UITapGestureRecognizer(target: self, action: #selector(deleteTaskPrompt))
        trashImageView.addGestureRecognizer(deleteTap)
        
        var statusText = "TODO"
        if (completed) {
            statusText = "COMPLETED"
        }
        
        statusLabel.text = statusText
        statusLabel.textColor = .lightGray
        statusLabel.font = getPrimaryFont(.medium, size: 12)
        
        taskTextView.text = task.text
        taskTextView.font = getPrimaryFont(.medium, size: 22)
        taskTextView.textColor = .black
        taskTextView.translatesAutoresizingMaskIntoConstraints = true
        taskTextView.isScrollEnabled = false
        taskTextView.sizeToFit()
        taskTextView.showsVerticalScrollIndicator = false
        taskTextView.delegate = self
        
        noteLabel.text = "NOTE"
        noteLabel.textColor = .lightGray
        noteLabel.font = getPrimaryFont(.medium, size: 12)
        
        noteTextView.text = task.note
        noteTextView.font = getPrimaryFont(.regular, size: 18)
        noteTextView.textColor = .black
        noteTextView.translatesAutoresizingMaskIntoConstraints = true
        noteTextView.isScrollEnabled = false
        noteTextView.sizeToFit()
        noteTextView.showsVerticalScrollIndicator = false
        noteTextView.delegate = self
        
        textViewPlaceholder.text = "Add a note"
        textViewPlaceholder.textColor = .lightGray
        textViewPlaceholder.font = getPrimaryFont(.regular, size: 18)
        if (task.note != "") {
            textViewPlaceholder.alpha = 0
        }
        
        divider.backgroundColor = .superLightGray
    
        view.addSubview(scrollView)
        
        scrollView.addSubviews([statusLabel, taskTextView, closeImageView, noteLabel, noteTextView, divider, textViewPlaceholder, trashImageView])
    }

    private func setConstraints() {
        scrollView.snp.makeConstraints { (make) in
            make.left.right.bottom.top.equalTo(self.view)
        }
        
        closeImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER - 25)
            make.left.equalTo(15)
            make.height.width.equalTo(20)
        }

        trashImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER - 19)
            make.height.width.equalTo(18)
            make.right.equalTo(view.snp.right).offset(-15)
        }
        
        statusLabel.snp.makeConstraints { (make) in
            make.top.equalTo(closeImageView.snp.bottom).offset(30)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.height.equalTo(10)
            make.centerX.equalTo(self.view)
        }
        
        taskTextView.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel.snp.bottom).offset(5)
            make.left.equalTo(statusLabel).offset(-6)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
        }
        
        divider.snp.makeConstraints { (make) in
            make.top.equalTo(taskTextView.snp.bottom).offset(10)
            make.width.equalTo(self.view)
            make.height.equalTo(30)
        }
        
        noteLabel.snp.makeConstraints { (make) in
            make.top.equalTo(divider.snp.bottom).offset(20)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.height.equalTo(10)
            make.centerX.equalTo(self.view)
        }
        
        noteTextView.snp.makeConstraints { (make) in
            make.top.equalTo(noteLabel.snp.bottom).offset(5)
            make.left.equalTo(statusLabel).offset(-6)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.bottom.equalTo(scrollView.snp.bottom)
        }
        
        textViewPlaceholder.snp.makeConstraints { (make) in
            make.top.width.left.equalTo(noteTextView)
            make.height.equalTo(30)
        }
    }
    
    private func applyDismissKeyboardGesture() {
        dismissKeyboardSwipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardSwipe.direction = .down
        dismissKeyboardSwipe.delegate = self
        view.addGestureRecognizer(dismissKeyboardSwipe)
    }
    
    private func deleteTask() {
        let realm = try! Realm()
        try! realm.write {
            realm.delete(task)
        }
        
        closeView(deletedTask: true)
    }
    
    @objc func closeView(deletedTask: Bool = false) {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        if (!completed && deletedTask) {
            delegate?.dismissDetailView(deletedActiveTask: true)
        } else {
            delegate?.dismissDetailView(deletedActiveTask: false)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            savedYValue = scrollView.contentOffset.y
            keyboardIsShown = true
            scrollView.isScrollEnabled = false
            
            taskTextView.snp.makeConstraints { (make) in
                self.taskTextViewHeightConstraint = make.height.equalTo(scrollView.frame.height - keyboardSize.height - SAFE_BUFFER - 20).constraint
            }

            noteTextView.snp.makeConstraints({ (make) in
                self.noteTextViewHeightConstraint = make.height.equalTo(scrollView.frame.height - keyboardSize.height - SAFE_BUFFER - 20).constraint
            })
            
            taskTextView.isScrollEnabled = true
            noteTextView.isScrollEnabled = true
            
            view.layoutIfNeeded()
        }
    }
    
    @objc func dismissKeyboard() {
        scrollView.setContentOffset(CGPoint(x: 0, y: savedYValue), animated: true)
        
        scrollView.isScrollEnabled = true
        if (taskTextView.text == "") {
            taskTextView.text = task.text
        } else {
            let realm = try! Realm()
            try! realm.write {
                task.text = taskTextView.text
                task.note = noteTextView.text
            }
        }
        
        if (taskTextViewHeightConstraint != nil) {
            taskTextViewHeightConstraint.deactivate()
        }
        
        if (noteTextViewHeightConstraint != nil) {
            noteTextViewHeightConstraint.deactivate()
        }
        
        taskTextView.isScrollEnabled = false
        noteTextView.isScrollEnabled = false
        
        view.endEditing(true)
    }
    
    @objc func deleteTaskPrompt() {
        let alert = UIAlertController(title: "Are you sure?", message: "This task and all it's associated data will be deleted. This cannot be undone", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteTask()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)        
    }
    
}

extension TaskViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension TaskViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < -UIScreen.main.bounds.height*0.18 &&
            !keyboardIsShown) {
            closeView(deletedTask: false)
        }
    }
    
}

extension TaskViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if (textView == noteTextView) {
            textViewPlaceholder.alpha = 0
            scrollView.setContentOffset(CGPoint(x: 0, y: noteLabel.frame.origin.y - SAFE_BUFFER), animated: true)
        } else {
            scrollView.setContentOffset(CGPoint(x: 0, y: statusLabel.frame.origin.y - SAFE_BUFFER), animated: true)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView == noteTextView &&
            textView.text == "") {
            textViewPlaceholder.alpha = 1
        }
        
        keyboardIsShown = false
    }
    
}
