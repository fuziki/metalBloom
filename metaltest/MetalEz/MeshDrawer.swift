//
//  MeshDrawer.swift
//  metaltest
//



import MetalKit
import simd


extension MetalEz {
    class MeshDrawer {
        private var mesh: MTKMesh
        var texture: MTLTexture
        private var frameUniformBuffer: MTLBuffer
        private weak var mtlEz: MetalEz!
        var hidden: Bool = false
        init(mtlEz m: MetalEz ,mesh v: MTKMesh, texture t: MTLTexture) {
            mtlEz = m
            mesh = v
            texture = t
            frameUniformBuffer = mtlEz.device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])!
        }
        func set(modelMatrix: matrix_float4x4) {
            let p = frameUniformBuffer.contents().assumingMemoryBound(to: FrameUniforms.self)
            let viewModelMatrix = matrix_multiply(mtlEz.cameraMatrix, modelMatrix)
            p.pointee.projectionViewMatrinx = matrix_multiply(mtlEz.projectionMatrix, viewModelMatrix)
            let mat3 = Utils.toUpperLeft3x3(from4x4: viewModelMatrix)
            p.pointee.normalMatrinx = mat3.transpose.inverse
        }
        func draw() {
            if hidden == true { return }
            mtlEz.mtlRenderCommandEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)   //do each model
            mtlEz.mtlRenderCommandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1) //do each model
            mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texture, index: 0)    //do each model
            mtlEz.mtlRenderCommandEncoder.setFragmentTexture(nil, index: 1)    //do each model
            mtlEz.mtlRenderCommandEncoder.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                                                                indexCount: mesh.submeshes[0].indexCount,
                                                                indexType: mesh.submeshes[0].indexType,
                                                                indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                                                                indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)   //do each model
        }
        func draw2() {
            if hidden == true { return }
            mtlEz.mtlRenderCommandEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)   //do each model
            mtlEz.mtlRenderCommandEncoder.setVertexBuffer(frameUniformBuffer, offset: 0, index: 1) //do each model
            mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texture, index: 0)    //do each model
            mtlEz.mtlRenderCommandEncoder.setFragmentTexture(texture, index: 1)    //do each model
            mtlEz.mtlRenderCommandEncoder.drawIndexedPrimitives(type: mesh.submeshes[0].primitiveType,
                                                                indexCount: mesh.submeshes[0].indexCount,
                                                                indexType: mesh.submeshes[0].indexType,
                                                                indexBuffer: mesh.submeshes[0].indexBuffer.buffer,
                                                                indexBufferOffset: mesh.submeshes[0].indexBuffer.offset)   //do each model
        }
    }
    
}


















