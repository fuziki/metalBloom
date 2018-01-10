//
//  Realship
//  metaltest
//



import simd
import MetalKit


class Realship {
    weak var world: World!
    var drawer: MetalEz.MeshDrawer
    private var rot: Float = 180.0
    init(world myworld: World) {
        world = myworld
        let tex = world.mtlEz.loader.loadTexture(name: "shipDiffuse", type: "png")
        let mesh = world.mtlEz.loader.loadMesh(name: "realship")
        drawer = MetalEz.MeshDrawer(mtlEz: world.mtlEz ,mesh: mesh, texture: tex)
    }
    func update() {
//        rot += 1
        var mat = matrix_identity_float4x4
        mat = matrix_multiply(mat, Utils.translation(float3(-0.3, -0.5, 2)))
        mat = matrix_multiply(mat, Utils.rotation_y(radians: toRad(fromDeg: rot)))
        drawer.set(modelMatrix: mat)
    }
    func draw(type: MetalEzRenderingEngine.RendererType) {
//        if type == .mesh_nonlighting {
            drawer.draw()
        print("draw realship")
//        }
    }
}






