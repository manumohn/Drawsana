//
//  BezierShape.swift
//  Drawsana
//
//  Created by Manu Mohan on 02/01/20.
//

import Foundation

public class BezierShape: Shape,
    ShapeWithStandardState,
    ShapeWithBezierPath,
ShapeSelectable {
    
    private enum CodingKeys: String, CodingKey {
        case id, strokeColor, fillColor, strokeWidth, type, transform
    }
    
    public var id: String = UUID().uuidString
    public var strokeColor: UIColor? = .black
    public var fillColor: UIColor? = .clear
    public var strokeWidth: CGFloat = 3
    public static var type: String = "BezierShape"
    public var transform: ShapeTransform = .identity
    private var _bezierPath: UIBezierPath
    
    public var bezierPath: UIBezierPath    {
        let bez = UIBezierPath(cgPath: _bezierPath.cgPath)
        bez.apply(transform.affineTransform)
        return bez
    }
    
    public init(bezierPath: UIBezierPath) {
        _bezierPath = bezierPath
    }
    
    
    public var boundingRect: CGRect {
        return _bezierPath.bounds.insetBy(dx: -strokeWidth/2.0, dy: -strokeWidth/2.0)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try values.decode(String.self, forKey: .type)
        if type != BezierShape.type {
            throw DrawsanaDecodingError.wrongShapeTypeError
        }
        transform = try values.decodeIfPresent(ShapeTransform.self, forKey: .transform) ?? .identity
        
        id = try values.decode(String.self, forKey: .id)
        
        strokeColor = try values.decodeColorIfPresent(forKey: .strokeColor)
        fillColor = try values.decodeColorIfPresent(forKey: .fillColor)
        
        strokeWidth = try values.decode(CGFloat.self, forKey: .strokeWidth)
        _bezierPath = UIBezierPath()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(EllipseShape.type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(strokeColor?.hexString, forKey: .strokeColor)
        try container.encode(fillColor?.hexString, forKey: .fillColor)
        try container.encode(strokeWidth, forKey: .strokeWidth)
        
        if !transform.isIdentity {
            try container.encode(transform, forKey: .transform)
        }
    }
    
    public func render(in context: CGContext) {
        transform.begin(context: context)
        if let fillColor = fillColor {
            context.setFillColor(fillColor.cgColor)
            context.addPath(_bezierPath.cgPath)
            context.fillPath()
        }
        
        context.setLineWidth(strokeWidth)
        
        if let strokeColor = strokeColor {
            context.setStrokeColor(strokeColor.cgColor)
            context.setLineDash(phase: 0, lengths: [])
            context.addPath(_bezierPath.cgPath)
            context.strokePath()
        }
        transform.end(context: context)
    }
    
    public func hitTest(point: CGPoint) -> Bool {
        return bezierPath.contains(point)
    }
    
}
