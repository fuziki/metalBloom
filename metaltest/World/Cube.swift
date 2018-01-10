//
//  Cube.swift
//  metaltest
//


import simd
import MetalKit

class Cube {
    weak var world: World!
    private var drawer: MetalEz.MeshDrawer
    private var rot: Float = 0.2
    init(world myworld: World) {
        world = myworld
        let tex = world.mtlEz.loader.loadTexture(name: "default", type: "png")
        let mesh = world.mtlEz.loader.loadMesh(name: "cube")
        drawer = MetalEz.MeshDrawer(mtlEz: world.mtlEz ,mesh: mesh, texture: tex)
    }
    func update() {
//        rot += 0.3
        var mat = matrix_identity_float4x4
        mat = matrix_multiply(mat, Utils.translation(float3(0.7, -1, 4)))
        mat = matrix_multiply(mat, Utils.rotation_x(radians: toRad(fromDeg: rot)))
        drawer.set(modelMatrix: mat)
    }
    func draw(type: MetalEzRenderingEngine.RendererType) {
//        if type ==  {
        for _ in 0..<100 {
            update()
            drawer.draw2()
        print("draw cube")
        }
//        }
    }
}







