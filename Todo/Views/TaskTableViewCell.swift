//
//  TaskTableViewCell.swift
//  Todo
//
//  Created by Jake Shelley on 12/5/17.
//  Copyright © 2017 Jake Shelley. All rights reserved.
//

import UIKit

protocol TaskTableViewCellDelegate: class {
    func changeTaskState(for cell: TaskTableViewCell)
    func showDetail(for cell: TaskTableViewCell)
}

class TaskTableViewCell: UITableViewCell {

    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var changeStateButton: UIButton!
    @IBOutlet weak var taskLabel: UILabel!
    private var crossView: UIView!
    weak var task: Task!
    weak var delegate: TaskTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        checkImage.tintColor = .lightGray
        
        crossView = UIView(frame: CGRect(x: taskLabel.frame.origin.x, y: (frame.height/2) + 0.75, width: 0, height: 1.5))
        crossView.backgroundColor = .lightGray
        addSubview(crossView)
    }
    
    func configure(with task: Task, completed: Bool) {
        self.task = task
        taskLabel.text = task.text
        if (completed) {
            setCompleteState()
        } else {
            setTodoState()
        }
        
        setGestureRecognizers()
    }
    
    private func setGestureRecognizers() {
        let changeStateSwipe = UISwipeGestureRecognizer(target: self, action: #selector(changeState))
        changeStateSwipe.direction = .right
        addGestureRecognizer(changeStateSwipe)

        let changeStateTap = UITapGestureRecognizer(target: self, action: #selector(showDetail))
        addGestureRecognizer(changeStateTap)
        
        changeStateButton.addTarget(self, action: #selector(changeState), for: .touchUpInside)
    }
    
    private func setCompleteState() {
        crossView.alpha = 0.8
        crossView.frame.size.width = taskLabel.intrinsicContentSize.width
        checkImage.image = UIImage(named: "check")
        taskLabel.textColor = .lightGray
    }
    
    private func setTodoState() {
        crossView.frame.size.width = 0
        crossView.alpha = 0
        checkImage.image = UIImage(named: "uncheck")
        taskLabel.textColor = .black
    }

    @objc func changeState() {
        delegate?.changeTaskState(for: self)
    }
    
    @objc func showDetail() {
        delegate?.showDetail(for: self)
    }
    
}
