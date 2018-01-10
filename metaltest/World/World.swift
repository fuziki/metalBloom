//
//  World.swift
//  metaltest
//



import simd
import MetalKit

class Camera {
    weak var world: World!
    init(world myworld: World) {
        world = myworld
    }
    func update() {
        world.mtlEz.lookAt(from: float3(0, 1, -1.5), direction: normalize(float3(0.0, -0.4, 1)), up: float3(0, 1, 0))
    }
}

class World {
    weak var mtlEz: MetalEz!
    private var camera: Camera!
    private var realship: Realship!
    private var cube: Cube!
    init(metalEz: MetalEz) {
        mtlEz = metalEz
        camera = Camera(world: self)
        realship = Realship(world: self)
        cube = Cube(world: self)
    }
    func update() {
        camera.update()
        realship.update()
        cube.update()
    }
    func draw(type: MetalEzRenderingEngine.RendererType) {
        switch type {
        case .mesh: break
            cube.draw(type: type)

        case .skinning: break

        case .mesh_add: break

        case .mesh_nonlighting: break
            realship.draw(type: type)

        case .targetMarker: break

        case .points: break

        case .explosion: break

        case .sea: break
            
        case .bloom:
            realship.draw(type: type)
            cube.draw(type: type)

        
        default: break
        }
    }
}


