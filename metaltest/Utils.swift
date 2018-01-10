//
//  matrix.swift
//  MetalTessellation
//
//

import simd

func toRad(fromDeg degrees: Float) -> Float {
    return degrees / 180.0 * .pi
}

class Utils {
    static func perspective(_ FieldOfView : Float, aspectRatio : Float, zFar : Float, zNear : Float) -> matrix_float4x4 {
        var m : matrix_float4x4 = matrix_float4x4()
        let f : Float = 1.0 / tan(FieldOfView / 2.0)
        m.columns.0.x = f / aspectRatio
        m.columns.1.y = f
        m.columns.2.z = zFar / (zFar - zNear)
        m.columns.2.w = 1.0
        m.columns.3.z = -(zNear*zFar)/(zFar-zNear)
        return m
    }
    static func lookAt(from: float3, direction: float3, up: float3) -> matrix_float4x4 {
        var m = matrix_float4x4()
        var right = cross(up, direction)
        
        m.columns.0 = float4(right.x, right.y, right.z, 0.0)
        m.columns.1 = float4(up.x, up.y, up.z, 0.0)
        m.columns.2 = float4(direction.x, direction.y, direction.z, 0.0)
        m.columns.3 = float4(from.x, from.y, from.z, 1.0)
        m = m.inverse
        return m
    }
    static func rotation_z(radians: Float) -> matrix_float4x4 {
        var m : matrix_float4x4 = matrix_identity_float4x4
        m.columns.0.x = cos(radians)
        m.columns.0.y = sin(radians)
        m.columns.1.x = -sin(radians)
        m.columns.1.y = cos(radians)
        return m
    }
    static func rotation_y(radians: Float) -> matrix_float4x4 {
        var m : matrix_float4x4 = matrix_identity_float4x4
        m.columns.0.x =  cos(radians)
        m.columns.0.z = -sin(radians)
        m.columns.2.x = sin(radians)
        m.columns.2.z = cos(radians)
        return m
    }
    static func rotation_x(radians: Float) -> matrix_float4x4 {
        var m : matrix_float4x4 = matrix_identity_float4x4
        m.columns.1.y = cos(radians)
        m.columns.1.z = sin(radians)
        m.columns.2.y = -sin(radians)
        m.columns.2.z =  cos(radians)
        return m
    }
    static func scale(_ data: float3) -> matrix_float4x4 {
        var m = matrix_identity_float4x4
        m.columns.0.x = data.x
        m.columns.1.y = data.y
        m.columns.2.z = data.z
        return m
    }
    static func translation(_ data: float3) -> matrix_float4x4 {
        var m : matrix_float4x4 = matrix_identity_float4x4
        m.columns.3.x = data.x
        m.columns.3.y = data.y
        m.columns.3.z = data.z
        return m
    }    
    static func toUpperLeft3x3(from4x4 m: matrix_float4x4) -> matrix_float3x3 {
        let x = m.columns.0
        let y = m.columns.1
        let z = m.columns.2
        return matrix_float3x3(columns: (vector_float3(x.x, x.y, x.z),
                                         vector_float3(y.x, y.y, y.z),
                                         vector_float3(z.x, z.y, z.z)))
    }
}



