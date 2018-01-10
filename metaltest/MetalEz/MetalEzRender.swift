//
//  MetalEzRender.swift
//  metaltest
//


import MetalKit
import simd

struct FrameUniforms {
    var projectionViewMatrinx: matrix_float4x4
    var normalMatrinx: matrix_float3x3
}

class MetalEzRenderingEngine {
    enum RendererType: Int {
        case mesh
        case mesh_add
        case mesh_nonlighting
        case skinning
        case targetMarker
        case points
        case explosion
        case sea
        case mydefault
        
        case bloom
    }
    weak var mtlEz: MetalEz!
    static let blendingIsEnabled = "BlendingIsEnabled"
    init(MetalEz _metalEz: MetalEz) {
        mtlEz = _metalEz
    }

}

class MetalEzMmeshRenderer: MetalEzRenderingEngine {
    init(MetalEz metalEz: MetalEz, pipelineDic: inout Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>) {
        super.init(MetalEz: metalEz)
        let mtlVertex = makeMTLVertexDescriptor()

        pipelineDic[.mesh] =
            try! mtlEz.device.makeRenderPipelineState(descriptor: makeMTLRenderPassDescriptor(vertex: mtlVertex))
        
        pipelineDic[.mesh_add] =
            try! mtlEz.device.makeRenderPipelineState(descriptor: makeMTLRenderPassDescriptor4add(vertex: mtlVertex))
        
        pipelineDic[.mesh_nonlighting] =
            try! mtlEz.device.makeRenderPipelineState(descriptor: makeMTLRenderPassDescriptor4nonlighting(vertex: mtlVertex))
        
    }
    private func makeMTLVertexDescriptor() -> MTLVertexDescriptor {
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
    private func makeMTLRenderPassDescriptor(vertex: MTLVertexDescriptor) -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertex
        renderDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLight")
        renderDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        return renderDescriptor
    }
    private func makeMTLRenderPassDescriptor4add(vertex: MTLVertexDescriptor) -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertex
        renderDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightAdd")
        renderDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        
        renderDescriptor.colorAttachments[0].isBlendingEnabled = true   //blending alpha config is here
        renderDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        
        renderDescriptor.label = MetalEzRenderingEngine.blendingIsEnabled
        
        return renderDescriptor
    }
    private func makeMTLRenderPassDescriptor4nonlighting(vertex: MTLVertexDescriptor) -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderDescriptor = MTLRenderPipelineDescriptor()
        renderDescriptor.vertexDescriptor = vertex
        renderDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderDescriptor.vertexFunction = library.makeFunction(name: "lambertVertex")
        renderDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightNonl")
        renderDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        
        return renderDescriptor
    }
    func draw(mesh:MTKMesh, texture:MTLTexture, fuBuffer:MTLBuffer) {
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)   //do each model
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(fuBuffer, offset: 0, index: 1) //do each model
        mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texture, index: 0)    //do each model
        mtlEz.mtlRenderCommandEncoder.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                                                            indexCount: mesh.submeshes[0].indexCount,
                                                            indexType: mesh.submeshes[0].indexType,
                                                            indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                                                            indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)   //do each model
    }
}


struct MetalEzExplosionRendererPoint {
    var point: float4
    var size: Float
    var len: Float
    var gain: Float = 0
    var dummy: Float = 0
}
class MetalEzExplosionRenderer: MetalEzRenderingEngine {
    init(MetalEz metalEz: MetalEz, pipelineDic: inout Dictionary<MetalEzRenderingEngine.RendererType, MTLRenderPipelineState>) {
        super.init(MetalEz: metalEz)
        let renderDescriptor = makeMTLRenderPassDescriptor()
        let mtlRenderPipelineState = try! mtlEz.device.makeRenderPipelineState(descriptor: renderDescriptor)
        pipelineDic[.explosion] = mtlRenderPipelineState
    }
    private func makeMTLRenderPassDescriptor() -> MTLRenderPipelineDescriptor {
        let library = mtlEz.device.makeDefaultLibrary()!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.sampleCount = mtlEz.mtkView.sampleCount
        renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "lambertVertexExplosion")
        renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentLightExplosion")
        renderPipelineDescriptor.depthAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = mtlEz.mtkView.colorPixelFormat
        renderPipelineDescriptor.stencilAttachmentPixelFormat = mtlEz.mtkView.depthStencilPixelFormat

        renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true   //blending alpha config is here
        renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one

        renderPipelineDescriptor.label = MetalEzRenderingEngine.blendingIsEnabled
        
        return renderPipelineDescriptor
    }
    func draw(vaertex: MTLBuffer, frameUniformBuffer: MTLBuffer, texure: MTLTexture, count: Int) {
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(vaertex, offset: 0, index: 0)
        mtlEz.mtlRenderCommandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1)
        mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texure, index: 0)
        mtlEz.mtlRenderCommandEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: count, instanceCount: 1)
    }
    func makeVertexBuffer(count: Int) -> MTLBuffer {
        let verBff = mtlEz.device.makeBuffer(length: MemoryLayout<MetalEzExplosionRendererPoint>.size * count, options: [])
        return verBff!
    }
    func set(points: [MetalEzExplosionRendererPoint], buffer: inout MTLBuffer) {
        let pvb = buffer.contents().assumingMemoryBound(to: MetalEzExplosionRendererPoint.self)
        for i in 0..<points.count {
            pvb.advanced(by: i).pointee = points[i]
        }
    }
    func set(modelMatrix: matrix_float4x4, frameUniformBuffer _myfubuff: inout MTLBuffer) {
        let p = _myfubuff.contents().assumingMemoryBound(to: FrameUniforms.self)
        let viewModelMatrix = matrix_multiply(mtlEz.cameraMatrix, modelMatrix)
        p.pointee.projectionViewMatrinx = matrix_multiply(mtlEz.projectionMatrix, viewModelMatrix)
        let mat3 = Utils.toUpperLeft3x3(from4x4: viewModelMatrix)
        p.pointee.normalMatrinx = mat3.transpose.inverse

    }
}



























