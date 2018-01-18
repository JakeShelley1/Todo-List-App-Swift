//
//  ListViewController.swift
//  Todo
//
//  Created by Jake Shelley on 12/1/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit
import SnapKit
import RealmSwift
import UICountingLabel

enum ListViewState {
    case expanded
    case expanding
    case minimized
    case minimizing
}

class ListViewController: UIViewController {
    
    private let impactNotifier = UIImpactFeedbackGenerator()
    private let kBuffer: CGFloat = 15
    private let addTaskButtonHeight: CGFloat = 50
    private let reuseIdentifier = "TaskCell"
    
    var addingTask = false
    var buttonLeftConstraint: Constraint!
    var taskList: TaskList!
    private var state: ListViewState = .minimized
    private var kButtonMargin: CGFloat!
    weak var delegate: ListViewDelegate?
    lazy var titleLabel = UILabel()
    lazy var todosLabel = UILabel()
    lazy var progressLabel = UICountingLabel()
    lazy var progressBar = UISlider()
    lazy var iconView = UIView()
    lazy var iconImageView = UIImageView()
    lazy var tableView = UITableView(frame: CGRect(), style: .grouped)
    lazy var backImageView = UIImageView()
    lazy var editTableImageView = UIImageView()
    lazy var addTaskButton = UIButton()
    lazy var addTaskButtonShadow = UIView()
    lazy var buttonGradient = CAGradientLayer()
    lazy var addTaskView = AddTaskView()
    lazy var editButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.cornerRadius = 8
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = CGSize(width: 0, height: 20)
        view.backgroundColor = .white
        kButtonMargin = view.bounds.height*0.78
        
        buildUI()
        setConstraints()
    }
    
    func expand() {
        guard state != .expanding else { return }

        addTaskView.setKeyboardObserver()
        state = .expanding
        
        UIView.animate(withDuration: SHORT_ANIMATION_DURATION) {
            self.editButton.alpha = 0
        }
        
        UIView.animate(withDuration: LONG_ANIMATION_DURATION, animations: {
            self.view.layer.cornerRadius = 0
            self.progressBar.snp.updateConstraints { (make) -> Void in
                make.left.equalTo(self.kBuffer + (UIScreen.main.bounds.width - MINIMIZED_LIST_WIDTH)/2)
                make.top.equalTo(UIScreen.main.bounds.height * 0.36)
            }
            
            self.iconView.snp.updateConstraints { (make) -> Void in
                make.top.equalTo(UIScreen.main.bounds.height * 0.36 - 150)
            }

            self.tableView.snp.updateConstraints { (make) in
                 make.bottom.equalTo(self.view)
            }
            
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIApplication.shared.statusBarStyle = .default
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: MEDIUM_ANIMATION_DURATION, animations: {
                self.tableView.alpha = 1
                self.tableView.isUserInteractionEnabled = true
                self.backImageView.alpha = 1
                self.backImageView.isUserInteractionEnabled = true
                self.addTaskButton.alpha = 1
                self.addTaskButton.isUserInteractionEnabled = true
                self.addTaskButtonShadow.alpha = 1
                self.editTableImageView.alpha = 1
                self.editTableImageView.isUserInteractionEnabled = true
            })
        }
    }
    
    func minimize() {
        guard state != .minimizing else { return }
        
        tableView.setEditing(false, animated: true)
        editTableImageView.tintColor = .lightGray
        
        addTaskView.removeKeyboardObserver()
        state = .minimizing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            UIView.animate(withDuration: SHORT_ANIMATION_DURATION) {
                self.editButton.alpha = 1
            }
        }
        
        UIView.animate(withDuration: LONG_ANIMATION_DURATION, animations: {
            self.view.layer.cornerRadius = 8
            self.progressBar.snp.updateConstraints { (make) -> Void in
                make.left.equalTo(self.kBuffer)
                make.top.equalTo(self.view).offset(MINIMIZED_LIST_HEIGHT - 40)
            }
            
            self.iconView.snp.updateConstraints { (make) -> Void in
                make.top.equalTo(self.kBuffer)
            }
            
            self.view.layoutIfNeeded()
            UIApplication.shared.statusBarStyle = .lightContent
        })
        
        UIView.animate(withDuration: MEDIUM_ANIMATION_DURATION, animations: {
            self.tableView.alpha = 0
            self.backImageView.alpha = 0
            self.backImageView.isUserInteractionEnabled = false
            self.tableView.isUserInteractionEnabled = false
            self.addTaskButton.alpha = 0
            self.addTaskButton.isUserInteractionEnabled = false
            self.addTaskButtonShadow.alpha = 0
            self.editTableImageView.alpha = 0
            self.editTableImageView.isUserInteractionEnabled = false
        })
    }
    
    private func buildUI() {
        todosLabel.font = getPrimaryFont(.regular, size: 15)
        todosLabel.textColor = .lightGray
        
        titleLabel.font = getPrimaryFont(.medium, size: 33)
        titleLabel.text = taskList.title
        titleLabel.textColor = .black
        
        progressLabel.font = getPrimaryFont(.medium, size: 15)
        progressLabel.textColor = .lightGray
        progressLabel.format = "%d"
        
        progressBar.tintColor = colorSchemes[taskList.colorSchemeId]["primary"]
        progressBar.maximumTrackTintColor = .superLightGray
        progressBar.setThumbImage(UIImage(), for: .normal)
        progressBar.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        progressBar.isUserInteractionEnabled = false
        progressLabel.textAlignment = .right
        
        iconView.layer.cornerRadius = 25
        iconView.layer.borderColor = UIColor.superLightGray.cgColor
        iconView.layer.borderWidth = 1
        
        iconImageView.image = iconImages[taskList.imageNameId]
        iconImageView.tintColor = colorSchemes[taskList.colorSchemeId]["primary"]
        iconView.addSubview(iconImageView)
        
        editButton.setImage(UIImage(named: "dots"), for: .normal)
        editButton.tintColor = .lightGray
        editButton.adjustsImageWhenHighlighted = false
        editButton.addTarget(self, action: #selector(beginListEdit), for: .touchUpInside)
        
        backImageView.image = UIImage(named: "back")
        backImageView.alpha = 0
        backImageView.isUserInteractionEnabled = false
        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(minimizeFromBackButton))
        backImageView.addGestureRecognizer(backTapGesture)
        
        editTableImageView.image = UIImage(named: "updown")
        editTableImageView.alpha = 0
        editTableImageView.isUserInteractionEnabled = false
        let editTapGesture = UITapGestureRecognizer(target: self, action: #selector(editTableButtonPress))
        editTableImageView.addGestureRecognizer(editTapGesture)
        editTableImageView.tintColor = .lightGray
        
        tableView.register(UINib(nibName: "TaskTableViewCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        tableView.alpha = 0
        tableView.separatorColor = .superLightGray
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        
        addTaskButton.layer.cornerRadius = addTaskButtonHeight/2
        addTaskButton.clipsToBounds = true
        addTaskButton.adjustsImageWhenHighlighted = false
        buttonGradient.bounds = CGRect(x: 0,
                                       y: 0,
                                       width: addTaskButtonHeight,
                                       height: addTaskButtonHeight)
        buttonGradient.transform = CATransform3DScale(CATransform3DMakeTranslation(addTaskButtonHeight/2, addTaskButtonHeight/2, 0), 1, 1, 0)
        let colorScheme = colorSchemes[taskList.colorSchemeId]
        buttonGradient.colors = [colorScheme["secondary"]!.cgColor, colorScheme["primary"]!.cgColor]
        buttonGradient.startPoint = CGPoint(x: 0, y: 0)
        buttonGradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        addTaskButton.layer.insertSublayer(buttonGradient, below: addTaskButton.imageView?.layer)
        addTaskButton.setImage(#imageLiteral(resourceName: "plus"), for: .normal)
        addTaskButton.alpha = 0
        addTaskButton.addTarget(self, action: #selector(addTaskButtonPress), for: .touchUpInside)
        
        addTaskButtonShadow.backgroundColor = .white
        addTaskButtonShadow.alpha = 0
        addTaskButtonShadow.layer.cornerRadius = addTaskButtonHeight/2
        addTaskButtonShadow.layer.shadowColor = UIColor.black.cgColor
        addTaskButtonShadow.layer.shadowOffset = CGSize(width: 0, height: 6)
        addTaskButtonShadow.layer.shadowOpacity = 0.4
        
        addTaskView.primaryColor = colorSchemes[taskList.colorSchemeId]["primary"]
        addTaskView.build()
        addTaskView.delegate = self
        
        setProgress()
        view.addSubviews([todosLabel, titleLabel, progressBar, progressLabel, iconView, tableView, backImageView, editTableImageView, addTaskButtonShadow, addTaskButton, editButton])
        view.insertSubview(addTaskView, belowSubview: addTaskButtonShadow)
    }

    
    private func setConstraints() {
        progressBar.snp.makeConstraints { (make) in
            make.height.equalTo(25)
            make.left.equalTo(kBuffer)
            make.width.equalTo(MINIMIZED_LIST_WIDTH - 72)
            make.top.equalTo(self.view).offset(MINIMIZED_LIST_HEIGHT - 40)
        }
        
        progressLabel.snp.makeConstraints { (make) in
            make.height.equalTo(25)
            make.width.equalTo(28)
            make.top.equalTo(progressBar)
            make.left.equalTo(progressBar.snp.right).offset(kBuffer - 10)
        }
        
        let percentLabel = UILabel()
        percentLabel.font = progressLabel.font
        percentLabel.text = "%"
        percentLabel.textColor = .lightGray
        view.insertSubview(percentLabel, belowSubview: progressBar)
        percentLabel.snp.makeConstraints { (make) in
            make.height.equalTo(progressLabel)
            make.width.equalTo(15)
            make.top.equalTo(progressLabel)
            make.left.equalTo(progressLabel.snp.right).offset(1)
        }
        
        
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.width.equalTo(progressBar)
            make.right.equalTo(progressBar)
            make.bottom.equalTo(progressBar.snp.top).offset(-10)
        }

        todosLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.equalTo(titleLabel)
            make.right.equalTo(progressBar)
            make.bottom.equalTo(titleLabel.snp.top)
        }
        
        iconView.snp.makeConstraints { (make) in
            make.height.width.equalTo(50)
            make.left.equalTo(progressBar).offset(-4)
            make.top.equalTo(kBuffer)
        }
        
        iconImageView.snp.makeConstraints { (make) in
            make.height.width.equalTo(25)
            make.center.equalTo(iconView)
        }
        
        editButton.snp.makeConstraints { (make) in
            make.height.width.equalTo(28)
            make.left.equalTo(progressLabel).offset(17)
            make.centerY.equalTo(iconImageView)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(progressBar.snp.bottom).offset(15)
            make.left.equalTo(progressBar)
            make.bottom.equalTo(UIScreen.main.bounds.height * 0.36)
            make.width.equalTo(MINIMIZED_LIST_WIDTH - kBuffer*2)
        }
        
        backImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER)
            make.left.equalTo(15)
            make.height.width.equalTo(20)
        }
        
        editTableImageView.snp.makeConstraints { (make) in
            make.top.equalTo(SAFE_BUFFER)
            make.left.equalTo(self.view.frame.width - 35)
            make.height.width.equalTo(20)
        }
        
        addTaskButton.snp.makeConstraints { (make) in
            make.height.equalTo(addTaskButtonHeight).priority(.required)
            make.width.equalTo(addTaskButtonHeight)
            make.top.equalTo(self.kButtonMargin)
            self.buttonLeftConstraint = make.left.equalTo(self.tableView.snp.right).offset(-25).constraint
        }
        
        addTaskButtonShadow.snp.makeConstraints { (make) in
            make.height.width.equalTo(addTaskButtonHeight - 3)
            make.top.equalTo(addTaskButton)
            make.left.equalTo(addTaskButton)
        }
        
        addTaskView.snp.makeConstraints { (make) in
            make.height.equalTo(UIScreen.main.bounds.height)
            make.width.equalTo(UIScreen.main.bounds.width)
            make.top.equalTo(UIScreen.main.bounds.height)
        }
    }

    private func calculatePercentageComplete(numCompleted: Int, total: Int) -> Float {
        if (total == 0 || numCompleted == 0) { return 0 }
        return Float(numCompleted)/Float(total)
    }
    
    private func setTodosLabel() {
        todosLabel.text = String(taskList.activeTasks.count) + (taskList.activeTasks.count == 1 ? " Task" : " Tasks")
    }
    
    private func setProgress() {
        let percentComplete = calculatePercentageComplete(numCompleted: taskList.completedTasks.count, total: taskList.getTotalTasks())
        UIView.animate(withDuration: SHORT_ANIMATION_DURATION, delay: 0, options: .curveEaseIn, animations: {
            self.progressBar.setValue(percentComplete, animated: true)
        }, completion: nil)
        
        var fromValue: CGFloat!
        
        if (progressLabel.text == nil) {
            fromValue = 0
        } else {
            fromValue = CGFloat((progressLabel.text! as NSString).floatValue)
        }

        progressLabel.method = .easeIn
        progressLabel.animationDuration = SHORT_ANIMATION_DURATION
        progressLabel.count(from: fromValue, to: CGFloat(percentComplete * 100))
        setTodosLabel()
    }
    
    private func showAddTaskView() {
        UIView.animate(withDuration: SHORT_ANIMATION_DURATION) {
            self.addTaskView.snp.updateConstraints { (make) in
                make.top.equalTo(self.view.snp.top)
            }
            
            self.view.layoutIfNeeded()
        }
        
        addTaskView.showView()
    }
    
    private func commitTask() {
        let realm = try! Realm()
        guard let text = addTaskView.textView.text else { return }
        guard text != "" else { return }
        
        let task = Task()
        task.text = text
        try! realm.write {
            taskList.activeTasks.insert(task, at: 0)
        }
        
        impactNotifier.impactOccurred()
        tableView.reloadSections([0], with: .automatic)
        addTaskView.dismissKeyboard()
        closeAddTaskView()
        addTaskView.textView.text = ""
        delegate?.updateTodoTotal(incrementBy: 1)
        setTodosLabel()
    }
    
    @objc func minimizeFromBackButton() {
        delegate?.minimize()
    }
    
    @objc func addTaskButtonPress() {
        if (addingTask == true) {
            commitTask()
            return
        }
        
        tableView.setEditing(false, animated: true)
        editTableImageView.tintColor = .lightGray
        
        addingTask = true
        UIView.animate(withDuration: 0.08, animations: {
            self.addTaskView.alpha = 1
            self.addTaskButtonShadow.layer.shadowOpacity = 0
            self.addTaskButton.snp.updateConstraints({ (make) in
                make.top.equalTo(self.kButtonMargin + 2)
            })
            self.view.layoutIfNeeded()
        }, completion: { _ in
            UIView.animate(withDuration: 0.08, animations: {
                self.addTaskButtonShadow.layer.shadowOpacity = 0.4
                self.addTaskButton.snp.updateConstraints({ (make) in
                    make.top.equalTo(self.kButtonMargin)
                })
            }, completion: { _ in
                self.showAddTaskView()
            })
            
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func beginListEdit() {
        delegate?.beginListEdit()
    }
    
    @objc func editTableButtonPress() {
        if (tableView.isEditing) {
            tableView.setEditing(false, animated: true)
            editTableImageView.tintColor = .lightGray
        } else {
            tableView.setEditing(true, animated: true)
            editTableImageView.tintColor = colorSchemes[taskList.colorSchemeId]["primary"]
        }
    }
    
}

extension ListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0: return taskList.activeTasks.count
            default: return taskList.completedTasks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as! TaskTableViewCell
        if (indexPath.section == 0) {
            cell.configure(with: taskList.activeTasks[indexPath.row], completed: false)
        } else {
            cell.configure(with: taskList.completedTasks[indexPath.row], completed: true)
        }
        
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        let label = UILabel()
        if (section == 0) {
            label.text = "TODO"
        } else {
            label.text = "COMPLETED"
        }
        
        label.font = getPrimaryFont(.medium, size: 12)
        label.textColor = .lightGray
        header.addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(5)
            make.height.equalTo(header)
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
            return sourceIndexPath
        }
        
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let realm = try! Realm()
        try! realm.write {
            if (sourceIndexPath.section == 0) {
                let movedTask = taskList.activeTasks[sourceIndexPath.row]
                taskList.activeTasks.remove(at: sourceIndexPath.row)
                taskList.activeTasks.insert(movedTask, at: destinationIndexPath.row)
            } else {
                let movedTask = taskList.completedTasks[sourceIndexPath.row]
                taskList.completedTasks.remove(at: sourceIndexPath.row)
                taskList.completedTasks.insert(movedTask, at: destinationIndexPath.row)
            }
        }
    }
    
}

extension ListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y < -60) {
            delegate?.minimize()
        }
    }
    
}

extension ListViewController: AddTaskViewDelegate {
    
    func updateButtonFrame(with keyboardHeight: CGFloat) {
        buttonLeftConstraint.deactivate()
        UIView.animate(withDuration: MEDIUM_ANIMATION_DURATION, animations: {
            self.addTaskButton.snp.updateConstraints({ (make) in
                make.width.equalTo(UIScreen.main.bounds.width)
                make.top.equalTo(UIScreen.main.bounds.height - keyboardHeight - self.addTaskButtonHeight)
                
            })
            
            self.addTaskButton.snp.makeConstraints({ (make) in
                self.buttonLeftConstraint = make.left.equalTo(0).constraint
            })
        
            self.addTaskButton.layer.cornerRadius = 0
            self.buttonGradient.bounds = CGRect(x: 0,
                                                y: UIScreen.main.bounds.height - keyboardHeight - self.addTaskButtonHeight,
                                                width: UIScreen.main.bounds.width*2,
                                                height: self.addTaskButtonHeight)
            self.view.layoutIfNeeded()
        })
    }
    
    func closeAddTaskView() {
        UIView.animate(withDuration: SHORT_ANIMATION_DURATION) {
            self.addTaskView.alpha = 0
            self.addTaskView.snp.updateConstraints({ (make) in
                make.top.equalTo(UIScreen.main.bounds.height)
            })
            
            self.view.layoutIfNeeded()
        }
        
        buttonLeftConstraint.deactivate()
        
        UIView.animate(withDuration: MEDIUM_ANIMATION_DURATION, animations: {
            self.buttonGradient.bounds = CGRect(x: 0,
                                                y: 0,
                                                width: self.addTaskButtonHeight,
                                                height: self.addTaskButtonHeight)
            
            self.addTaskButton.snp.updateConstraints { (make) in
                make.width.equalTo(self.addTaskButtonHeight)
                make.top.equalTo(self.kButtonMargin)
            }
            
            self.addTaskButton.snp.makeConstraints({ (make) in
                self.buttonLeftConstraint = make.left.equalTo(self.tableView.snp.right).offset(-25).constraint
            })
            
            self.addTaskButton.layer.cornerRadius = self.addTaskButtonHeight/2
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.addingTask = false
        })
    }
    
}

extension ListViewController: TaskTableViewCellDelegate {
    
    func showDetail(for cell: TaskTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        tableView.setEditing(false, animated: true)
        editTableImageView.tintColor = .lightGray
        
        let vc = TaskViewController()
        if (indexPath.section == 0) {
            vc.task = taskList.activeTasks[indexPath.row]
            vc.completed = false
        } else {
            vc.task = taskList.completedTasks[indexPath.row]
            vc.completed = true
        }
    
        addTaskView.removeKeyboardObserver()
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    func changeTaskState(for cell: TaskTableViewCell) {
        let realm = try! Realm()
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        try! realm.write {
            if (indexPath.section == 0) {
                let task = taskList.activeTasks[indexPath.row]
                taskList.activeTasks.remove(at: indexPath.row)
                taskList.completedTasks.insert(task, at: 0)
                delegate?.updateTodoTotal(incrementBy: -1)
            } else {
                let task = taskList.completedTasks[indexPath.row]
                taskList.completedTasks.remove(at: indexPath.row)
                taskList.activeTasks.insert(task, at: 0)
                delegate?.updateTodoTotal(incrementBy: 1)
            }
        }

        impactNotifier.impactOccurred()
        setProgress()
        tableView.reloadSections([0, 1], with: .none)
    }
    
}

extension ListViewController: TaskViewControllerDelegate {
    
    func dismissDetailView(deletedActiveTask: Bool) {
        addTaskView.setKeyboardObserver()
        if (deletedActiveTask) {
            delegate?.updateTodoTotal(incrementBy: -1)
            setTodosLabel()
            impactNotifier.impactOccurred()
        }
        
        tableView.reloadSections([0, 1], with: .none)
    }
    
}
