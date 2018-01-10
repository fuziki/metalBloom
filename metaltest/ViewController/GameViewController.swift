//
//  GameViewController.swift
//  metaltest
//

import MetalKit
import MetalPerformanceShaders
import simd


class GameViewController: UIViewController, MetalEzClassDelegate {
    private var mtlEz: MetalEz!
    private var world: World!
    
    @IBOutlet weak var myMTKView: MTKView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mtlEz = MetalEz()
        mtlEz.delegate = self
        mtlEz.setupMetal(mtkView: self.view as! MTKView!)
        world = World(metalEz: self.mtlEz)
        print("metal ez is start")
        
    }
    func update() {
        world.update()
    }
    func draw(type: MetalEzRenderingEngine.RendererType) {
        world.draw(type: type)
    }
}











