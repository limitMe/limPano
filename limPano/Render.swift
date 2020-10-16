//
//  Render.swift
//  limPano
//
//  Created by zhongdian on 2020/10/13.
//

import UIKit
import MetalKit
import CoreGraphics

class  Renderer: NSObject, MTKViewDelegate {
    
    // MARK: Metal objects
    private let _sampleCount = 4
    private var _device: MTLDevice!
    private var _commandQueue: MTLCommandQueue!
    private var _renderPipelineState: MTLRenderPipelineState!
    private var _renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    private var _verticesBuffer: MTLBuffer!
    private var _fragmentBuffer: MTLBuffer!
    private var _texture: MTLTexture!
    
    init(_ mtkView: MTKView) {
        super.init()

        // MARK: Setup pipeline
        mtkView.device = MTLCreateSystemDefaultDevice()!
        mtkView.preferredFramesPerSecond = 120
        mtkView.sampleCount = _sampleCount
        _device = mtkView.device
        
        let library = _device.makeDefaultLibrary()!
        _renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        // load MSL here
        _renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        _renderPipelineDescriptor.sampleCount = _sampleCount

        do {
            _renderPipelineState = try _device.makeRenderPipelineState(descriptor: _renderPipelineDescriptor)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
        
        mtkView.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1.0)
        mtkView.isOpaque = true

        _commandQueue = _device.makeCommandQueue()!

        mtkView.delegate = self
        
        // MARK: Setup Texture
        let image = UIImage(named: "pano");
        let textureDescriptor = MTLTextureDescriptor();
        textureDescriptor.pixelFormat = MTLPixelFormat.rgba8Unorm
        textureDescriptor.width = 2000
        textureDescriptor.height = 1000
        self._texture = mtkView.device?.makeTexture(descriptor: textureDescriptor)
        let origin = MTLOrigin(x: 0, y: 0, z: 0)
        let size = MTLSize(width: 2000, height: 1000, depth: 1)
        let region = MTLRegion(origin: origin, size: size)
        let imageBytes = self.loadImage(image: image!)
        self._texture.replace(region: region, mipmapLevel: 0, withBytes: imageBytes, bytesPerRow: 4*Int(image!.size.width))
    }
    
    func loadImage(image: UIImage) -> [UInt8] {
        let inputImage: CGImage = image.cgImage!
        let width = inputImage.width
        let height = inputImage.height
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: inputImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(inputImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pointer = context?.data?.assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: pointer, count: width * height * 4)
        return Array(buffer)
    }
    
    // MARK: MTK delegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        
    }
}
