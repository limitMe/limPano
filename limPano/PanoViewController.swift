//
//  PanoViewController.swift
//  limPano
//
//  Created by zhongdian on 2020/10/13.
//

import UIKit
import SwiftUI
import MetalKit

struct PanoView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PanoViewController
    
    func makeUIViewController(context: Context) -> PanoViewController {
        let panoVC = PanoViewController()
        return panoVC
    }
    
    func updateUIViewController(_ uiViewController: PanoViewController, context: Context) {
        // left blanc
    }
}

class PanoViewController: UIViewController {
    private var _mtkView: MTKView!
    private var _renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _mtkView = MTKView(frame: self.view.frame)
        self.view = _mtkView

        _renderer = Renderer(_mtkView)
        _mtkView.delegate = _renderer
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch began")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch moved")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch ended")
    }
    
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        print("estimated properties updated")
    }
}
