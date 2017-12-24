//
//  CustomListViewController.swift
//  Todo
//
//  Created by Jake Shelley on 12/19/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit
import RealmSwift

protocol CustomListViewDelegate: class {
    func reloadTaskLists()
}

class CustomListViewController: UIViewController {

    private let NUMBER_OF_CELLS = 5
    private let cellHeight: CGFloat = 50
    private let kBuffer: CGFloat = 15
    private let colorIdentifier = "ColorCell"
    private let iconIdentifier = "IconCell"
    
    var taskList = TaskList()
    var newTaskList = false
    private var colorCollectionView: UICollectionView!
    private var iconCollectionView: UICollectionView!
    private var imageNameId: Int = 0
    private var colorSchemeId: Int = 0
    weak var delegate: CustomListViewDelegate?
    lazy var closeImageView = UIImageView()
    lazy var trashImageView = UIImageView()
    lazy var listTitleTextField = UITextField()
    lazy var iconLabel = UILabel()
    lazy var colorLabel = UILabel()
    lazy var titleLabel = UILabel()
    lazy var saveButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.statusBarStyle = .default
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        view.backgroundColor = .white
        
        imageNameId = taskList.imageNameId
        colorSchemeId = taskList.colorSchemeId
        
        buildUI()
        setConstraints()
        listTitleTextField.becomeFirstResponder()
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeView))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    private func buildUI() {
        closeImageView.image = UIImage(named: "x")
        closeImageView.tintColor = .lightGray
        let closeTap = UITapGestureRecognizer(target: self, action: #selector(closeView))
        closeImageView.addGestureRecognizer(closeTap)
        closeImageView.isUserInteractionEnabled = true
        
        trashImageView.image = UIImage(named: "trash")
        if (newTaskList) {
            trashImageView.tintColor = .superLightGray
        } else {
            trashImageView.tintColor = .redOrange
            trashImageView.isUserInteractionEnabled = true
        }
        
        let deleteTap = UITapGestureRecognizer(target: self, action: #selector(deleteList))
        trashImageView.addGestureRecognizer(deleteTap)
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: cellHeight, height: cellHeight)
        var collectionFrame = CGRect(x: 0,
                                     y: SAFE_BUFFER + 55,
                                     width: (CGFloat(NUMBER_OF_CELLS)*layout.minimumInteritemSpacing) + (CGFloat(NUMBER_OF_CELLS)*cellHeight),
                                     height: cellHeight)
        collectionFrame.origin.x = (view.frame.width - collectionFrame.width)/2
        
        iconCollectionView = UICollectionView(frame: collectionFrame, collectionViewLayout: layout)
        iconCollectionView.backgroundColor = .white
        iconCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: iconIdentifier)
        iconCollectionView.dataSource = self
        iconCollectionView.delegate = self
        
        colorCollectionView = UICollectionView(frame: collectionFrame, collectionViewLayout: layout)
        colorCollectionView.backgroundColor = .white
        colorCollectionView.frame.origin.y = collectionFrame.origin.y + collectionFrame.height + 35
        colorCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: colorIdentifier)
        colorCollectionView.dataSource = self
        colorCollectionView.delegate = self
    
        iconLabel.text = "ICON"
        iconLabel.textColor = .lightGray
        iconLabel.font = getPrimaryFont(.medium, size: 12)
        
        colorLabel.text = "COLOR"
        colorLabel.textColor = .lightGray
        colorLabel.font = getPrimaryFont(.medium, size: 12)
        
        titleLabel.text = "TITLE"
        titleLabel.textColor = .lightGray
        titleLabel.font = getPrimaryFont(.medium, size: 12)
        
        listTitleTextField.text = taskList.title
        listTitleTextField.font = getPrimaryFont(.medium, size: 33)
        listTitleTextField.textColor = .black
        listTitleTextField.tintColor = colorSchemes[colorSchemeId]["secondary"]
        listTitleTextField.addTarget(self, action: #selector(titleDidChange), for: .allEditingEvents)
        
        saveButton.setTitle("SAVE", for: .normal)
        saveButton.backgroundColor = listTitleTextField.text == "" ? .superLightGray : colorSchemes[colorSchemeId]["secondary"]
        saveButton.titleLabel?.font = getPrimaryFont(.bold, size: 12)
        saveButton.addTarget(self, action: #selector(commitTaskList), for: .touchUpInside)
        
        view.addSubviews([closeImageView, trashImageView, iconCollectionView, colorCollectionView, iconLabel, colorLabel, titleLabel, listTitleTextField, saveButton])
    }
    
    private func setConstraints() {
        closeImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER)
            make.left.equalTo(15)
            make.height.width.equalTo(20)
        }
        
        trashImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER + 2)
            make.height.width.equalTo(18)
            make.right.equalTo(view.snp.right).offset(-15)
        }
        
        iconLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(iconCollectionView.snp.top).offset(-5)
            make.centerX.equalTo(self.view)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.height.equalTo(12)
        }
        
        colorLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(colorCollectionView.snp.top).offset(-5)
            make.centerX.equalTo(self.view)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.height.equalTo(12)
        }
        
        listTitleTextField.snp.makeConstraints { (make) in
            make.top.equalTo(colorCollectionView.snp.bottom).offset(35)
            make.height.equalTo(50)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.centerX.equalTo(self.view)
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(listTitleTextField.snp.top).offset(-5)
            make.centerX.equalTo(self.view)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.height.equalTo(12)
        }
        
        saveButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(0)
            make.height.equalTo(45)
            make.left.right.equalTo(self.view)
        }
    }
    
    @objc func deleteList() {
        let alert = UIAlertController(title: "Are you sure?", message: "This list and all it's associated data will be deleted. This cannot be undone", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            let realm = try! Realm()
            try! realm.write {
                realm.delete(self.taskList)
            }
            
            self.closeView()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)

    }
    
    @objc func closeView() {
        view.endEditing(true)
        delegate?.reloadTaskLists()
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        dismiss(animated: true, completion: nil)
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            saveButton.snp.updateConstraints({ (make) in
                make.bottom.equalTo(-keyboardSize.height)
            })
            
            view.layoutIfNeeded()
        }
    }
    
    @objc func commitTaskList() {
        if (listTitleTextField.text == "") { return }
        
        let realm = try! Realm()
        try! realm.write {
            taskList.imageNameId = imageNameId
            taskList.colorSchemeId = colorSchemeId
            taskList.title = listTitleTextField.text!
            
            if (newTaskList) {
                taskList.id = taskList.incrementID()
                realm.add(taskList)
            }
        }
        
        closeView()
    }
    
    @objc func titleDidChange() {
        if listTitleTextField.text == "" {
            UIView.animate(withDuration: SHORT_ANIMATION_DURATION) {
                self.saveButton.backgroundColor = .superLightGray
                self.saveButton.isUserInteractionEnabled = false
            }
        } else {
            UIView.animate(withDuration: SHORT_ANIMATION_DURATION) {
                self.saveButton.backgroundColor = colorSchemes[self.colorSchemeId]["secondary"]
                self.saveButton.isUserInteractionEnabled = true
            }
        }
    }
}

extension CustomListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NUMBER_OF_CELLS // Bug not allowing me to assign specific # of items in each tableview
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!
        if (collectionView == colorCollectionView) {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: colorIdentifier, for: indexPath)
            
            // Remove any existing gradients otherwise it reorders
            cell.layer.sublayers?.forEach {
                if ($0.name == "gradientCell") {
                    $0.removeFromSuperlayer()
                }
            }
            
            let gradient = CAGradientLayer()
            gradient.frame = cell.bounds
            gradient.name = "gradientCell"
            let colorScheme = colorSchemes[indexPath.row]
            gradient.colors = [colorScheme["secondary"]!.cgColor, colorScheme["primary"]!.cgColor]
            cell.layer.insertSublayer(gradient, at: 0)
            cell.clipsToBounds = true
            
            if (colorSchemeId == indexPath.row) {
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 2
            } else {
                cell.layer.borderWidth = 0
            }
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: iconIdentifier, for: indexPath)
            cell.layer.borderColor = UIColor.superLightGray.cgColor
            cell.layer.borderWidth = 1
            
            // Clear cell of imageview
            cell.subviews.forEach { $0.removeFromSuperview() }
            
            let iconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 18, height: 18))
            iconImageView.image = iconImages[indexPath.item]
            iconImageView.tintColor = colorSchemes[colorSchemeId]["primary"]
            cell.addSubview(iconImageView)
            iconImageView.snp.makeConstraints({ (make) in
                make.centerX.centerY.equalTo(cell)
            })
            
            if (imageNameId == indexPath.row) {
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 2
            }
        }
        
        cell.layer.cornerRadius = cellHeight/2
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: cellHeight, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (collectionView == colorCollectionView) {
            colorSchemeId = indexPath.row
            colorCollectionView.reloadData()
            
            UIView.animate(withDuration: SHORT_ANIMATION_DURATION, animations: {
                self.saveButton.backgroundColor = self.listTitleTextField.text == "" ? .superLightGray : colorSchemes[self.colorSchemeId]["secondary"]
                self.listTitleTextField.tintColor = colorSchemes[self.colorSchemeId]["secondary"]
            })
            
        } else {
            imageNameId = indexPath.row
        }
        
        iconCollectionView.reloadData()
    }

}

extension CustomListViewController: UICollectionViewDelegate {}
