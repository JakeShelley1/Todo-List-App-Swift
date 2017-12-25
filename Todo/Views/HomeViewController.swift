//
//  HomeViewController.swift
//  Todo
//
//  Created by Jake Shelley on 11/27/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit
import RealmSwift
import SnapKit

protocol ListViewDelegate: class {
    func minimize()
    func beginListEdit()
    func updateTodoTotal(incrementBy: Int)
}

class HomeViewController: UIViewController {

    private let gradient = CAGradientLayer()
    
    @IBOutlet weak var listScrollView: UIScrollView!
    lazy var timeLabel = UILabel()
    lazy var greetingLabel = UILabel()
    lazy var subtitleLabel = UILabel()
    lazy var dateLabel = UILabel()
    private var listIndex = 0 // Index of currently shown list
    private var listViewBaseYPos: CGFloat!
    private var kBuffer: CGFloat!
    private var scrollingIsDisabled = false
    private var firstLoad = true
    private var newTaskListButton: UIButton!
    private var firstTimer: Timer!
    private var secondTimer: Timer!
    private var taskCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startClock()
        
        listScrollView.layer.masksToBounds = false
        listScrollView.showsHorizontalScrollIndicator = false
        listScrollView.isScrollEnabled = false
        let scrollSwipeGestureRight = UISwipeGestureRecognizer(target: self, action: #selector(handleScroll))
        scrollSwipeGestureRight.direction = .right
        listScrollView.addGestureRecognizer(scrollSwipeGestureRight)
        let scrollSwipeGestureLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleScroll))
        scrollSwipeGestureLeft.direction = .left
        listScrollView.addGestureRecognizer(scrollSwipeGestureLeft)
        listViewBaseYPos = UIScreen.main.bounds.height * 0.4
        kBuffer = (view.bounds.width - MINIMIZED_LIST_WIDTH)/2
        
        gradient.frame = view.bounds
        
        addLists()
        buildLabels()
        view.bringSubview(toFront: listScrollView)
        let colorScheme = colorSchemes[(childViewControllers[0] as! ListViewController).taskList.colorSchemeId]
        gradient.colors = [colorScheme["secondary"]!.cgColor, colorScheme["primary"]!.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    // Hacky fix for bug where view does not appear as correct size except on iphone x
    override func viewDidAppear(_ animated: Bool) {
        if (firstLoad) {
            for vc in childViewControllers {
                vc.view.frame.size.height = MINIMIZED_LIST_HEIGHT
                vc.view.frame.size.width = MINIMIZED_LIST_WIDTH
            }
            
            firstLoad = false
        }
        
        super.viewDidAppear(animated)
    }
    
    private func setTimes() {
        let dateComponents = Calendar.current.dateComponents([.minute, .hour], from: Date())
        let formatter = DateFormatter()
        let hourText = dateComponents.hour! > 12 ? String(dateComponents.hour! - 12) : String(dateComponents.hour!)
        let minuteText = dateComponents.minute! < 10 ?  "0" + String(dateComponents.minute!) : String(dateComponents.minute!)
        formatter.dateFormat = "MMMM d, YYYY"
        
        timeLabel.text = hourText + ":" + minuteText
        dateLabel.text = formatter.string(from: Date()).uppercased()
        
        let hour = dateComponents.hour!
        switch (hour) {
        case _ where hour > 3 && hour < 12:
            greetingLabel.text = "Good morning."
            break
        case _ where hour > 11 && hour < 17:
            greetingLabel.text = "Good afternoon."
            break
        default:
            greetingLabel.text = "Good evening."
        }
    }
    
    private func startClock() {
        let currentSeconds = Calendar.current.component(.second, from: Date())
        let timeTillTopOfTheMinute = Double(60 - currentSeconds)
        firstTimer = Timer.scheduledTimer(withTimeInterval: timeTillTopOfTheMinute, repeats: false, block: { _ in
            self.setTimes()
            self.secondTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true, block: { _ in
                self.setTimes()
            })
        })
    }
    
    private func buildLabels() {
        dateLabel.font = getPrimaryFont(.bold, size: 12)
        dateLabel.textColor = .white
        
        timeLabel.font = getPrimaryFont(.medium, size: 34)
        timeLabel.textColor = .white
        
        greetingLabel.font = getPrimaryFont(.medium, size: 33)
        greetingLabel.textColor = .white
        
        let realm = try! Realm()
        taskCount = realm.objects(TaskList.self).flatMap({$0.activeTasks}).count
        subtitleLabel.font = getPrimaryFont(.regular, size: 15)
        subtitleLabel.textColor = .white
        subtitleLabel.text = "You have " + String(taskCount) + " tasks to do."
        
        setTimes()
        view.addSubviews([dateLabel, timeLabel, greetingLabel, subtitleLabel])
        setConstraints()
    }
    
    private func setConstraints() {
        dateLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(kBuffer + 5)
            make.width.equalTo(MINIMIZED_LIST_WIDTH)
            make.height.equalTo(10)
            make.topMargin.equalTo(listViewBaseYPos - 10)
        }
        
        timeLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(dateLabel)
            make.height.equalTo(40)
            make.width.equalTo(dateLabel)
            make.top.equalTo(self.view.bounds.height * 0.131)
        }
        
        greetingLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(dateLabel).offset(-1)
            make.height.equalTo(35)
            make.width.equalTo(dateLabel)
            make.top.equalTo(timeLabel).offset(44)
        }
        
        subtitleLabel.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(dateLabel).offset(4)
            make.height.equalTo(20)
            make.width.equalTo(dateLabel)
            make.top.equalTo(greetingLabel).offset(45)
        }
    }
    
    private func addLists() {
        let realm = try! Realm()
        for (index, taskList) in realm.objects(TaskList.self).sorted(byKeyPath: "id").enumerated() {
            buildTaskList(with: taskList, index: index)
        }
        
        let newTaskListButtonXPos = kBuffer + (kBuffer * CGFloat(childViewControllers.count)/2) + (CGFloat(childViewControllers.count) * MINIMIZED_LIST_WIDTH)
        if (newTaskListButton == nil) {
            newTaskListButton = UIButton(frame: CGRect(x: newTaskListButtonXPos,
                                                       y: listViewBaseYPos + 4,
                                                       width: MINIMIZED_LIST_WIDTH,
                                                       height: MINIMIZED_LIST_HEIGHT - 4))
            newTaskListButton.backgroundColor = .clear
            newTaskListButton.layer.cornerRadius = 8
            
            let buttonBorder = CAShapeLayer()
            buttonBorder.strokeColor = UIColor.white.cgColor
            buttonBorder.lineWidth = 4
            buttonBorder.lineDashPattern = [14, 15]
            buttonBorder.frame = newTaskListButton.bounds
            buttonBorder.fillColor = nil
            buttonBorder.path = UIBezierPath(roundedRect: newTaskListButton.bounds, cornerRadius: 8).cgPath
            newTaskListButton.layer.addSublayer(buttonBorder)
            newTaskListButton.setImage(#imageLiteral(resourceName: "plus"), for: .normal)
            newTaskListButton.addTarget(self, action: #selector(createNewList), for: .touchUpInside)
            listScrollView.addSubview(newTaskListButton)
        }
        
        newTaskListButton.frame.origin.x = newTaskListButtonXPos
        listScrollView.contentSize.width = view.frame.width*CGFloat(childViewControllers.count + 1)
    }
    
    private func buildTaskList(with taskList: TaskList, index: Int) {
        let xPos = kBuffer + (kBuffer * CGFloat(index)/2) + (CGFloat(index) * MINIMIZED_LIST_WIDTH)
        let listVC = ListViewController()
        listVC.taskList = taskList
        listVC.delegate = self
        
        let expandGesture = UISwipeGestureRecognizer(target: self, action: #selector(expandList))
        expandGesture.direction = .up
        listVC.view.addGestureRecognizer(expandGesture)
        let minimizeGesture = UISwipeGestureRecognizer(target: self, action: #selector(minimizeList))
        minimizeGesture.direction = .down
        listVC.view.addGestureRecognizer(minimizeGesture)
        
        addChildViewController(listVC)
        listVC.view.frame = CGRect(x: xPos,
                                   y: listViewBaseYPos,
                                   width: MINIMIZED_LIST_WIDTH,
                                   height: MINIMIZED_LIST_HEIGHT)
        listScrollView.addSubview(listVC.view)
        listVC.willMove(toParentViewController: self)
        listVC.didMove(toParentViewController: self)
    }
    
    private func animateGradientChange(with taskLists: Results<TaskList>) {
        var colorScheme: [String: UIColor]!
        
        if (listIndex == taskLists.count) {
            colorScheme = ["primary": .black, "secondary": .black]
        } else {
            colorScheme = colorSchemes[taskLists[listIndex].colorSchemeId]
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.gradient.colors = [
                colorScheme["secondary"]!.cgColor,
                colorScheme["primary"]!.cgColor
            ]
        }
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = MEDIUM_ANIMATION_DURATION
        gradientChangeAnimation.toValue = [
            colorScheme["secondary"]!.cgColor,
            colorScheme["primary"]!.cgColor
        ]
        gradientChangeAnimation.fillMode = kCAFillModeForwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
        CATransaction.commit()
    }
    
    @objc func expandList() {
        changeListSize(gestureDirection: .up, editing: false)
    }
    
    @objc func minimizeList() {
        changeListSize(gestureDirection: .down, editing: false)
    }
    
    @objc func handleScroll(gesture: UISwipeGestureRecognizer) {
        if (scrollingIsDisabled) { return }
        let realm = try! Realm()
        let taskLists = realm.objects(TaskList.self)
        switch (gesture.direction) {
            case .right:
                if (listIndex == 0) { return }
                listIndex -= 1
            case .left:
                if (listIndex == taskLists.count) { return }
                listIndex += 1
            default: return
        }
        
        listScrollView.setContentOffset(CGPoint(x: CGFloat(listIndex)*(MINIMIZED_LIST_WIDTH + kBuffer/2), y: 0), animated: true)
        animateGradientChange(with: taskLists)
    }
    
    // Editing param incase I want to do cooler editing animation later
    func changeListSize(gestureDirection: UISwipeGestureRecognizerDirection, editing: Bool) {
        let lvc = self.childViewControllers[listIndex] as! ListViewController
        if (lvc.addingTask) { return } // ignore swipe if user is adding task
        
        let viewBounds = self.view.bounds
        switch (gestureDirection) {
            case .up:
                scrollingIsDisabled = true
                listScrollView.bringSubview(toFront: lvc.view)
                lvc.expand()
                UIView.animate(withDuration: LONG_ANIMATION_DURATION, animations: {
                    var yPos: CGFloat = -20
                    if (UIDevice().type == .simulator) {
                        yPos = -45
                    }
                    
                    lvc.view.frame = CGRect(x: CGFloat(self.listIndex)*(self.listScrollView.frame.width - (self.kBuffer*1.5)),
                                            y: yPos,
                                            width: viewBounds.width,
                                            height: UIScreen.main.bounds.height)
                })
            case .down:
                let xPos = kBuffer + (kBuffer * CGFloat(listIndex)/2) + (CGFloat(listIndex) * MINIMIZED_LIST_WIDTH)
                lvc.minimize()
                UIView.animate(withDuration: LONG_ANIMATION_DURATION, animations: {
                    lvc.view.frame = CGRect(x: xPos,
                                            y: self.listViewBaseYPos,
                                            width: MINIMIZED_LIST_WIDTH,
                                            height: MINIMIZED_LIST_HEIGHT)
                }, completion: { _ in
                    self.scrollingIsDisabled = false
                })
            default: return
        }
    }
    
    @objc func createNewList() {
        presentCustomListView(newList: true)
    }
    
    private func presentCustomListView(newList: Bool) {
        let customListVC = CustomListViewController()
        if (listIndex < childViewControllers.count) {
            let lvc = childViewControllers[listIndex] as! ListViewController
            customListVC.taskList = lvc.taskList
        }
        
        customListVC.delegate = self
        customListVC.newTaskList = newList
        present(customListVC, animated: true, completion: nil)
    }
    
}

extension HomeViewController: ListViewDelegate {

    func minimize() {
        changeListSize(gestureDirection: .down, editing: false)
    }
    
    func beginListEdit() {
        presentCustomListView(newList: false)
    }
    
    func updateTodoTotal(incrementBy: Int) {
        taskCount += incrementBy
        subtitleLabel.text = "You have " + String(taskCount) + " tasks to do."
    }
    
}

extension HomeViewController: CustomListViewDelegate {
    
    func reloadTaskLists() {
        for vc in childViewControllers {
            vc.willMove(toParentViewController: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
        }
        
        addLists()
        
        if (listIndex > childViewControllers.count) {
            let fakeGesture = UISwipeGestureRecognizer()
            fakeGesture.direction = .right
            handleScroll(gesture: fakeGesture)
        }
        
        let realm = try! Realm()
        animateGradientChange(with: realm.objects(TaskList.self))
        
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
}
