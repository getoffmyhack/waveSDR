//
//  SidebarViewController.swift
//  waveSDR
//
//  Copyright © 2017 GetOffMyHack. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    
    //--------------------------------------------------------------------------
    //
    // MARK: - properties
    //
    //--------------------------------------------------------------------------
    

    //--------------------------------------------------------------------------
    //
    // MARK: - container views
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // main container view
    //
    //--------------------------------------------------------------------------
    
    var sidebarStackView:       NSStackView = {
        let view            = NSStackView()
        view.wantsLayer     = true
        view.orientation    = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
//        view.layer?.backgroundColor = NSColor.purple.cgColor
        return view
    }()
    
    //--------------------------------------------------------------------------
    //
    // MARK: - controls
    //
    //--------------------------------------------------------------------------
    

    
    //--------------------------------------------------------------------------
    //
    // MARK: - init / deinit
    //
    //--------------------------------------------------------------------------
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - override methods
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // loadView()
    //
    //--------------------------------------------------------------------------
    
    override func loadView() {
            
        self.view = NSView()
        self.view.wantsLayer    = true
        
        // build stack views
        setupStackViews()
        
        // add views
        view.addSubview(sidebarStackView)
        
    }
    
    //--------------------------------------------------------------------------
    //
    // viewDidLoad()
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        // Do view setup here.
        
        // build constraints
        setupConstraints()
        
    }
    
    //--------------------------------------------------------------------------
    //
    // MARK: - setup methods
    //
    // <setup> methods are called during the various phases of loading
    // and displaying the view controller's views
    //
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    //
    // setupStackViews()
    //
    // create the stack views that contain all the controls for the view
    //
    //--------------------------------------------------------------------------
    
    func setupStackViews() {
        
        for sidebarViewController in self.children {
            sidebarStackView.addView(sidebarViewController.view, in: .top)
            sidebarViewController.view.leadingAnchor.constraint(equalTo: self.sidebarStackView.leadingAnchor).isActive = true
            sidebarViewController.view.trailingAnchor.constraint(equalTo: self.sidebarStackView.trailingAnchor).isActive = true

        }

    }
    
    //--------------------------------------------------------------------------
    //
    // setupConstraints()
    //
    // create all the constraints needed to place and align all subviews
    //
    //--------------------------------------------------------------------------
    
    func setupConstraints() {
        
        sidebarStackView.topAnchor.constraint(              equalTo: self.view.topAnchor, constant: 10.0                ).isActive = true
        sidebarStackView.leadingAnchor.constraint(          equalTo: self.view.leadingAnchor                            ).isActive = true
        sidebarStackView.trailingAnchor.constraint(         equalTo: self.view.trailingAnchor                           ).isActive = true
        
    }
    
    
    //--------------------------------------------------------------------------
    //
    // MARK: - utility methods
    //
    //--------------------------------------------------------------------------
    
}
