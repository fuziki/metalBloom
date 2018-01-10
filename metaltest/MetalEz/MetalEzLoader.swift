//
//  MetalEzLoader.swift
//  metaltest
//



import MetalKit
import simd


class MetalEzLoader {
    weak var mtlEz: MetalEz!
    init(MetalEz: MetalEz) {
        mtlEz = MetalEz
    }
    func loadMesh(name modelName: String, needAddNomal: Bool = false) -> MTKMesh {
        print("load mesh \(modelName)")
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
        
        let modelDescriptor3D = MTKModelIOVertexDescriptorFromMetal(mtlVertex)    //use only Load obj
        (modelDescriptor3D.attributes[0] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (modelDescriptor3D.attributes[1] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (modelDescriptor3D.attributes[2] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let allocator = MTKMeshBufferAllocator(device: mtlEz.device)  //use only Load obj
        let asset = MDLAsset(url: Bundle.main.url(forResource: modelName, withExtension: "obj")!,
                             vertexDescriptor: modelDescriptor3D,
                             bufferAllocator: allocator)
        let newMesh = try! MTKMesh.newMeshes(asset: asset, device: mtlEz.device)
        return newMesh.metalKitMeshes.first!
    }
    func loadTexture(name textureName:String, type:String) -> MTLTexture {
        print("loadMtlTextureArray \(textureName).\(type)")
        let textureLoader = MTKTextureLoader(device: mtlEz.device)
        let newTexture =
            try? textureLoader.newTexture(URL: Bundle.main.url(forResource: textureName, withExtension: type)!, options: nil)
        return newTexture!
    }
    func makeFrameUniformBuffer() -> MTLBuffer {
        let bff = mtlEz.device.makeBuffer(length: MemoryLayout<FrameUniforms>.size, options: [])
        return bff!
    }
}









