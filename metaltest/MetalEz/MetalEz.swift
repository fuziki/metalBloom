
//
//  MetalEz.swift
//  metaltest
//


import MetalKit
import Metal
import MetalPerformanceShaders

protocol MetalEzClassDelegate {
    func update()
    func draw(type: MetalEzRenderingEngine.RendererType)
}

let maxBuffersInFlight = 3


class MetalEz: NSObject, MTKViewDelegate {
    var delegate: MetalEzClassDelegate?
    var mtkView: MTKView!
    var device: MTLDevice!
    
    private var commandQueue: MTLCommandQueue!
    private var depthStencilState: MTLDepthStencilState!
//    private var depthStencilStateForBlending: MTLDepthStencilState!
    private let semaphore = DispatchSemaphore(value: 1)

    private var mtlRenderPipelineStateArray = [(MetalEzRenderingEngine.RendererType, MTLRenderPipelineState)]()
    private var mtlRenderPipelineStateArrayForBlending = [(MetalEzRenderingEngine.RendererType, MTLRenderPipelineState)]()

    
    // MARK: metal data for draw objects
    var mtlRenderCommandEncoder:MTLRenderCommandEncoder!
    var cameraMatrix = matrix_identity_float4x4 //use by drawers, camera matrix update by look at
    var projectionMatrix = matrix_float4x4()    //use by drawers
    
    var mtlEzRenderingEngineArray = [MetalEzRenderingEngine]()
    var mesh: MetalEzMmeshRenderer!
    var loader: MetalEzLoader!
    var explosionEmitter: MetalEzExplosionRenderer!
    
    
    var viewRenderTexture: MTLTexture!
    var bloomRenderTexture: MTLTexture!
    var bloomedRenderTexture: MTLTexture!
    var drawableRenderTexture: MTLTexture!
    var bloomRenderPassDescriptor: MTLRenderPassDescriptor!
    
    var bloomPipelineState: MTLRenderPipelineState!
    
    
    
    
//    var bloomKernel: MPSImageGaussianBlur!
//    var bloomKernel: MPSImageConvolution!
//    var addKernel: MPSImageAdd!

    
    
    var computePipelineState: MTLComputePipelineState! = nil

    
    var viewWidth: Int!
    var viewHeight: Int!
    

    var threadGroupSize: MTLSize!
    var numGroups: MTLSize!

    

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    
    // MARK: metal initializer
    func setupMetal(mtkView view: MTKView) {
        print("setupMetal")
        mtkView = view
        
        mtkView.framebufferOnly = false
        
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()
        
        mtkView.sampleCount = 1
        mtkView.depthStencilPixelFormat = .depth32Float_stencil8
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.clearColor = MTLClearColorMake(0.2, 0.2, 0.2, 1.0)
        mtkView.device = device
        mtkView.delegate = self

        projectionMatrix = Utils.perspective(toRad(fromDeg: 30),
                                              aspectRatio: Float(mtkView.drawableSize.width / mtkView.drawableSize.height),
                                              zFar: 255,
                                              zNear: 0.1)

        
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthDescriptor)

/*        let depthDescriptorForBlending = MTLDepthStencilDescriptor()
        depthDescriptorForBlending.depthCompareFunction = .less
        depthDescriptorForBlending.isDepthWriteEnabled = false
        depthStencilStateForBlending = device.makeDepthStencilState(descriptor: depthDescriptorForBlending)*/
        
        var mtlRenderPipelineStateDictionary = Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>()

        loader = MetalEzLoader(MetalEz: self)
        mesh = MetalEzMmeshRenderer(MetalEz: self, pipelineDic: &mtlRenderPipelineStateDictionary)
        explosionEmitter = MetalEzExplosionRenderer(MetalEz: self, pipelineDic: &mtlRenderPipelineStateDictionary)
        
        for (key,val) in mtlRenderPipelineStateDictionary {
            print("dic: \(key), \(val.label ?? "non")")
            if val.label != nil {
                if (val.label?.contains(MetalEzRenderingEngine.blendingIsEnabled))! {
                    mtlRenderPipelineStateArrayForBlending.append((key, val))
                    print("add belnding")
                } else {
                    mtlRenderPipelineStateArray.append((key, val))
                    print("add nomal")
                }
            } else {
                mtlRenderPipelineStateArray.append((key, val))
                print("add nomal")
            }
        }
        
        
        
        
        
        
        
        viewWidth = Int(mtkView.drawableSize.width)
        viewHeight = Int(mtkView.drawableSize.height)

        
        
        threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        numGroups = MTLSize(
            width: viewWidth/threadGroupSize.width+1,
            height: viewHeight/threadGroupSize.height+1,
            depth: 1)
        
        
        
        
        viewRenderTexture = makeRenderTexture()
        
        bloomRenderTexture = makeRenderTexture()
        bloomedRenderTexture = makeHalfRenderTexture()
        bloomRenderPassDescriptor = makeBloomRenderPassDescriptor()
        bloomPipelineState = makeBloomRenderPipelineState()
        drawableRenderTexture = makeRenderTexture()
        
        
        
//        bloomKernel = MPSImageGaussianBlur(device: device, sigma: 25.0)
//        addKernel = MPSImageAdd(device: device)
        
        computePipelineState = makeAddComputePipelineState()
/*        let ksize: Int = 3
        var weights = [Float]()
        for _ in 0..<ksize*ksize {
            weights.append(1.0 / Float(ksize) / Float(ksize))
        }
        bloomKernel = MPSImageConvolution(device: device,
                                          kernelWidth: ksize,
                                          kernelHeight: ksize,
                                          weights: &weights)*/

        
        
        
        
    }
    func makeRenderTexture() -> MTLTexture {
        let texDesc = MTLTextureDescriptor()
        texDesc.width =  (mtkView.currentDrawable?.texture.width)!
        texDesc.height =  (mtkView.currentDrawable?.texture.height)!
        texDesc.depth = 1
        texDesc.textureType = MTLTextureType.type2D
        
        texDesc.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
        texDesc.storageMode = .private
        texDesc.pixelFormat = .bgra8Unorm
        
        texDesc.usage = .unknown
        
        return device.makeTexture(descriptor: texDesc)!
    }
    func makeHalfRenderTexture() -> MTLTexture {
        let texDesc = MTLTextureDescriptor()
        texDesc.width =  (mtkView.currentDrawable?.texture.width)! / 2
        texDesc.height =  (mtkView.currentDrawable?.texture.height)! / 2
        texDesc.depth = 1
        texDesc.textureType = MTLTextureType.type2D
        
        texDesc.usage = [MTLTextureUsage.renderTarget, MTLTextureUsage.shaderRead]
        texDesc.storageMode = .private
        texDesc.pixelFormat = .bgra8Unorm
        
        texDesc.usage = .unknown
        
        return device.makeTexture(descriptor: texDesc)!
    }
    func makeBloomRenderPassDescriptor() -> MTLRenderPassDescriptor {
        let black = MTLClearColor(red: 0.0, green: 0.0,
                                  blue: 0.0, alpha: 1.0)
        let black_2 = MTLClearColor(red: 0.0, green: 0.0,
                                    blue: 0.0, alpha: 0.0)
        
        
        let dsp = MTLRenderPassDescriptor()
        
        dsp.depthAttachment = mtkView.currentRenderPassDescriptor!.depthAttachment
        dsp.depthAttachment.loadAction = .clear
        dsp.depthAttachment.storeAction = .store
        dsp.stencilAttachment = mtkView.currentRenderPassDescriptor!.stencilAttachment
        dsp.stencilAttachment.loadAction = .clear
        dsp.stencilAttachment.storeAction = .store
        
//        dsp.colorAttachments[0].texture = mtkView.currentDrawable!.texture
        dsp.colorAttachments[0].texture = viewRenderTexture
        dsp.colorAttachments[0].loadAction = .clear
        dsp.colorAttachments[0].clearColor = black
        dsp.colorAttachments[0].storeAction = .store
        
        // `maskTexture` is a texture you must set up beforehand
        dsp.colorAttachments[1].texture = bloomRenderTexture
        dsp.colorAttachments[1].loadAction = .clear
        dsp.colorAttachments[1].clearColor = black_2
        dsp.colorAttachments[1].storeAction = .store
        
        return dsp
    }
    func makeBloomRenderPipelineDescriptor() -> MTLRenderPipelineDescriptor {
        func makeMTLVertexDescriptor() -> MTLVertexDescriptor {
            let mtlVertex = MTLVertexDescriptor()   //MTLRenderPipelineDescriptor.vertexDescriptor
            mtlVertex.attributes[0].format = .float3
            mtlVertex.attributes[0].offset = 0
            mtlVertex.attributes[0].bufferIndex = 0
            mtlVertex.attributes[1].format = .float3
            mtlVertex.attributes[1].offset = 12
            mtlVertex.attributes[1].bufferIndex = 0
            mtlVertex.attributes[2].format = .float2
            mtlVertex.attributes[2].offset = 24
            mtlVertex.attributes[2].bufferIndex = 0
            mtlVertex.layouts[0].stride = 32
            mtlVertex.layouts[0].stepRate = 1
            return mtlVertex
        }
        
        let library_s = device.makeDefaultLibrary()!
        let vertexProgram = library_s.makeFunction(name: "lambertVertex")
        let fragmentProgram = library_s.makeFunction(name: "fragmentShader")
        let descriptor = MTLRenderPipelineDescriptor()
        
        descriptor.vertexFunction = vertexProgram
        descriptor.fragmentFunction = fragmentProgram
        
        descriptor.sampleCount = mtkView.sampleCount

        
        descriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
        descriptor.colorAttachments[1].pixelFormat = .bgra8Unorm
        
        descriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        descriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat
        
        
        descriptor.vertexDescriptor = makeMTLVertexDescriptor()
        
        return descriptor
        
    }
    
    func makeBloomRenderPipelineState() -> MTLRenderPipelineState {
        let pipelineState_shadow: MTLRenderPipelineState!
        let descriptor = makeBloomRenderPipelineDescriptor()
        do {
            pipelineState_shadow = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch let error as NSError {
            fatalError("error: \(error.localizedDescription)")
        }
        return pipelineState_shadow
    }
    
    func makeAddComputePipelineState() -> MTLComputePipelineState {
        let library = device.makeDefaultLibrary()!
        let computeProgram = library.makeFunction(name: "computeShader")!
        let mycomputePipelineState: MTLComputePipelineState!
        do {
            mycomputePipelineState = try device.makeComputePipelineState(function: computeProgram)
        } catch {
            mycomputePipelineState = nil
            print("could not prepare compute pipeline state")
        }
        return mycomputePipelineState!
    }
    
    
    
    // MARK: set camera
    func lookAt(from: float3, direction: float3, up: float3) {
        cameraMatrix = Utils.lookAt(from: from, direction: direction, up: up)
    }
    // MARK: MTKViewDelegate
    func draw(in view: MTKView) {
        self.delegate?.update()
        autoreleasepool {
            _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
            let commandBuffer = commandQueue.makeCommandBuffer()
            let semaphore = inFlightSemaphore
            commandBuffer?.addCompletedHandler { (_ commandBuffer)-> Swift.Void in
                semaphore.signal()
            }

            mtlRenderCommandEncoder = (commandBuffer?.makeRenderCommandEncoder(descriptor: bloomRenderPassDescriptor))!
            mtlRenderCommandEncoder.setDepthStencilState(depthStencilState)
            mtlRenderCommandEncoder.setRenderPipelineState(bloomPipelineState)
            self.delegate?.draw(type: .bloom)
            mtlRenderCommandEncoder.endEncoding()
            
            var myTexture: MTLTexture? = bloomRenderTexture
            let kernel = MPSImageGaussianBlur(device: device, sigma: 20.0)
            kernel.encode(commandBuffer: commandBuffer!,
                          inPlaceTexture: &myTexture!, fallbackCopyAllocator: nil)
            
            let addKernel = MPSImageAdd(device: device)
            addKernel.encode(commandBuffer: commandBuffer!,
                             primaryTexture: viewRenderTexture,
                             secondaryTexture: bloomRenderTexture,
                             destinationTexture: (view.currentDrawable?.texture)!)
            
            commandBuffer?.present(view.currentDrawable!)
            commandBuffer?.commit()
        }
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}










