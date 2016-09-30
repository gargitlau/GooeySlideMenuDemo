//
//  GooeySlideMenu.swift
//  GooeySlideMenuDemo
//
//  Created by  on 16/9/29.
//  Copyright © 2016年 . All rights reserved.
//

import UIKit

typealias MenuButtonClickedBlock = (_ index: Int, _ title: String, _ titleCounts: Int)->()

struct MenuOptions {
    var titles : [String]
    var buttonHeight : CGFloat
    var menuColor : UIColor
    var blurStyle : UIBlurEffectStyle
    var buttonSpace : CGFloat
    var menuBlankWidth : CGFloat
    var menuClickBlock : MenuButtonClickedBlock
}

class GooeySlideMenu: UIView {
    fileprivate var _option: MenuOptions
    fileprivate var keyWindow: UIWindow?
    fileprivate var blurView: UIVisualEffectView!
    fileprivate var helperSideView: UIView!
    fileprivate var helperCenterView: UIView!
    
    fileprivate var diff: CGFloat = 0.0
    fileprivate var triggered = false
    fileprivate var displayLink: CADisplayLink?
    fileprivate var animationCount: Int = 0
    
    init(options: MenuOptions) {
        _option = options
        if let kWindow = UIApplication.shared.keyWindow {
            keyWindow = kWindow
            let frame = CGRect(
            x: -kWindow.frame.size.width / 2 - options.menuBlankWidth,
            y: 0,
            width: kWindow.frame.size.width / 2 + options.menuBlankWidth,
            height: kWindow.frame.size.height
            )
            super.init(frame:frame)
        } else {
            super.init(frame:CGRect.zero)
        }
        setUpViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint.zero)
        path.addLine(to: CGPoint(x: frame.width - _option.menuBlankWidth, y: 0))
        path.addQuadCurve(to: CGPoint(x: frame.width - _option.menuBlankWidth, y: frame.height), controlPoint: CGPoint(x: frame.width - _option.menuBlankWidth + diff, y: frame.height / 2))
        path.addLine(to: CGPoint(x: 0, y:frame.height))
        path.close()
        
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.addPath(path.cgPath)
        _option.menuColor.set()
        ctx?.fillPath()
    }
    
    func trigger() {
        if !triggered {
            if let keyWindow = keyWindow {
                keyWindow.insertSubview(blurView, belowSubview: self)
                UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
                    self?.frame = CGRect(
                        x:0,
                        y:0,
                        width: keyWindow.frame.size.width / 2 + self!._option.menuBlankWidth,
                        height: keyWindow.frame.height
                    )
                })
                
                beforeAnimation()
                
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.9, options: [.beginFromCurrentState, .allowUserInteraction], animations: { [weak self] () -> Void in
                    self?.helperSideView.center = CGPoint(x:self!.keyWindow!.center.x, y: self!.helperSideView.frame.size.height / 2)
                    }, completion: {[weak self] (finish) -> Void in
                        self?.finishAnimation()
                    })
                
                UIView.animate(withDuration: 0.3, animations: {[weak self]() in
                        self?.blurView.alpha = 1.0
                    })
                
                UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: [.beginFromCurrentState,.allowUserInteraction], animations: { [weak self] () -> Void in
                    self?.helperCenterView.center = CGPoint(x:self!.keyWindow!.center.x, y: self!.keyWindow!.center.y - self!.helperCenterView.frame.width / 2)
                    }, completion: { [weak self](finished) -> Void in
                        if finished {
                            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(GooeySlideMenu.tapToUntrigger))
                            self?.blurView.addGestureRecognizer(tapGesture)
                            self?.finishAnimation()
                        }
                })
                
                self.animateButtons()
                triggered = true
            }
        } else {
            self.tapToUntrigger()
        }
    }
}

extension GooeySlideMenu {
    fileprivate func setUpViews() {
        if let keyWindow = keyWindow {
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: _option.blurStyle))
            blurView.frame = keyWindow.frame
            blurView.alpha = 0.0
            
            helperSideView = UIView(frame: CGRect(x: -40, y: 0, width: 40, height: 40))
            helperSideView.backgroundColor = UIColor.yellow
            helperSideView.isHidden = true
            keyWindow.addSubview(helperSideView)
            
            helperCenterView = UIView(frame: CGRect(x: -40, y:(keyWindow.frame).height / 2 - 20, width: 40, height: 40))
            helperCenterView.backgroundColor = UIColor.yellow
            helperCenterView.isHidden = true
            keyWindow.addSubview(helperCenterView)
            
            backgroundColor = UIColor.clear
            keyWindow.insertSubview(self, belowSubview: helperSideView)
            self.addButton()
        }
    }
    
    private func addButton() {
        let titles = _option.titles
        if titles.count % 2 == 0 {
            var index_down = titles.count / 2
            var index_up = -1
            for i in 0..<titles.count {
                let title = titles[i]
                let buttonOption = MenuButtonOptions(title:title, buttonColor:_option.menuColor, buttonClickBlock:{[weak self]()->() in
                        self?.tapToUntrigger()
                        self?._option.menuClickBlock(i, title, titles.count)
                    })
                let home_button = SlideMenuButton(option: buttonOption)
                home_button.bounds = CGRect(x:0, y:0, width:frame.width - _option.menuBlankWidth - 20*2 , height: _option.buttonHeight)
                addSubview(home_button)
                
                if i >= titles.count / 2 {
                    index_up += 1
                    let y = frame.height / 2 + _option.buttonHeight * CGFloat(index_up) + _option.buttonSpace*CGFloat(index_up)
                    home_button.center = CGPoint(x: (frame.width - _option.menuBlankWidth) / 2, y: y + _option.buttonSpace / 2 + _option.buttonHeight / 2)
                } else {
                    index_down -= 1
                    let y = frame.height / 2 - _option.buttonHeight * CGFloat(index_down) - _option.buttonSpace * CGFloat(index_down)
                    home_button.center  = CGPoint(x: (frame.width - _option.menuBlankWidth) / 2, y: y - _option.buttonSpace / 2 - _option.buttonHeight / 2)
                }
            }
        } else {
            var index = (titles.count - 1) / 2 + 1
            for i in 0 ..< titles.count {
                index -= 1
                let title = titles[i]
                let buttonOption = MenuButtonOptions(title: title, buttonColor: _option.menuColor, buttonClickBlock:{[weak self] () in
                        self?.tapToUntrigger()
                        self?._option.menuClickBlock(i, title, titles.count)
                    })
                let home_button = SlideMenuButton(option: buttonOption)
                home_button.bounds = CGRect(x: 0, y:0, width:frame.width - _option.menuBlankWidth / 2 - 20 * 2, height: _option.buttonHeight)
                home_button.center = CGPoint(x: (frame.width - _option.menuBlankWidth) / 2, y: frame.height / 2 - _option.buttonHeight * CGFloat(index) - 20 * CGFloat(index))
                addSubview(home_button)
            }
        }
    }
    
    fileprivate func beforeAnimation() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(GooeySlideMenu.handleDisplayLinkAction(displaylink:)))
            displayLink?.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
        }
        animationCount += 1
    }
    
    fileprivate func finishAnimation() {
        animationCount -= 1
        if animationCount == 0 {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    fileprivate func animateButtons() {
        for i in 0..<subviews.count {
            let menuBtn = subviews[i]
            menuBtn.transform = CGAffineTransform(translationX:-90, y:0)
            UIView.animate(withDuration: 0.7, delay: Double(i) * (0.3 / Double(subviews.count)), usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                menuBtn.transform = CGAffineTransform.identity
                }, completion: nil)
        }
    }
    
    @objc fileprivate func tapToUntrigger() {
        UIView.animate(withDuration: 0.3) { [weak self] () in
            self?.frame = CGRect(x: -self!.keyWindow!.frame.width / 2 - self!._option.menuBlankWidth,
                                 y: 0,
                                 width: self!.keyWindow!.frame.width / 2 + self!._option.menuBlankWidth,
                                 height: self!.keyWindow!.frame.height)
        }
        beforeAnimation()
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.9, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
            self.helperSideView.center = CGPoint(x:-self.helperSideView.frame.height / 2, y:self.helperSideView.frame.height / 2)
            }) { [weak self](finish) in
                self?.finishAnimation()
        }
        
        UIView.animate(withDuration: 0.3) { 
            self.blurView.alpha = 0.0
        }
        
        beforeAnimation()
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 2.0, options: [.beginFromCurrentState, .allowUserInteraction], animations: {
                self.helperCenterView.center = CGPoint(x: -self.helperSideView.frame.height / 2, y: self.frame.height / 2)
            }) { (finish) in
                self.finishAnimation()
        }
        triggered = false
    }
    
    @objc fileprivate func handleDisplayLinkAction(displaylink: CADisplayLink) {
        if let sideHelperPresentationLayer = helperSideView.layer.presentation() {
            if let centerHelperPresentationLayer = helperCenterView.layer.presentation() {
                let centerRect = centerHelperPresentationLayer.frame
                let sideRect = sideHelperPresentationLayer.frame
                diff = sideRect.origin.x - centerRect.origin.x
            }
        }
        setNeedsDisplay()
    }
}
