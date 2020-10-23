//
//  Render.swift
//  limPano
//
//  Created by zhongdian on 2020/10/13.
//

import UIKit
import MetalKit
import CoreGraphics

struct SampleVertex {
    var position: vector_float4
    var textureCoordinate: vector_float2
    
    init(_ position: vector_float4, _ textureCoordinate: vector_float2) {
        self.position = position
        self.textureCoordinate = textureCoordinate
    }
}

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
    private var _numberVertices: Int!
    private var _viewportSize: vector_uint2!
    
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
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "samplingShader")
        _renderPipelineDescriptor.vertexFunction = vertexFunction
        _renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        _renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        _renderPipelineDescriptor.sampleCount = _sampleCount

        do {
            _renderPipelineState = try _device.makeRenderPipelineState(descriptor: _renderPipelineDescriptor)
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
        
        mtkView.clearColor = MTLClearColor(red: 1, green: 0, blue: 1, alpha: 1.0)
        mtkView.isOpaque = true

        _commandQueue = _device.makeCommandQueue()!
        
        // MARK: Setup Vertex
        let quadVertices: [SampleVertex] = [
            SampleVertex(SIMD4<Float>(1, -1, 0, 1), SIMD2<Float>(1,1)),
            SampleVertex(SIMD4<Float>(-1, -1, 0, 1), SIMD2<Float>(0,1)),
            SampleVertex(SIMD4<Float>(-1, 1, 0, 1), SIMD2<Float>(0,0)),
            
            SampleVertex(SIMD4<Float>(1, -1, 0.0, 1.0), SIMD2<Float>(1,1)),
            SampleVertex(SIMD4<Float>(-1, 1, 0.0, 1.0), SIMD2<Float>(0,0)),
            SampleVertex(SIMD4<Float>(1, 1, 0.0, 1.0), SIMD2<Float>(1,0)),
        ]
        self._numberVertices = quadVertices.count
        // Take care of MemoryLayout<T>.size and MemoryLayout<T>.stride!!!
        self._verticesBuffer = mtkView.device?.makeBuffer(bytes: quadVertices, length: self._numberVertices * MemoryLayout<SampleVertex>.stride, options: MTLResourceOptions.storageModeShared)

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

        self._texture.replace(region: region, mipmapLevel: 0, withBytes: imageBytes, bytesPerRow: 8*Int(image!.size.width))

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
        //print("called")
    }
    
    func draw(in view: MTKView) {
        let commandBuffer = self._commandQueue.makeCommandBuffer()
        let renderPassDescriptor = view.currentRenderPassDescriptor
        
        if(renderPassDescriptor != nil) {
            renderPassDescriptor?.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 1, alpha: 0)
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor!);
            renderEncoder!.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(view.drawableSize.width), height: Double(view.drawableSize.height ), znear: -1, zfar: 1))
            renderEncoder?.setRenderPipelineState(self._renderPipelineState)
            renderEncoder?.setVertexBuffer(self._verticesBuffer, offset: 0, index: 0)
            renderEncoder?.setFragmentTexture(self._texture, index: 0)
            renderEncoder?.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 6)
            renderEncoder?.endEncoding()
            commandBuffer?.present(view.currentDrawable! as MTLDrawable)
        }
        commandBuffer?.commit()
    }
}
