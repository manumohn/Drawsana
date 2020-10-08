//
//  ShapeDragHandler.swift
//  Drawsana
//
//  Created by Manu Mohan on 21/02/20.
//

import Foundation

class ShapeDragHandler {
    let shape: (ShapeWithBezierPath & ShapeWithTransform & ShapeWithBoundingRect)
    weak var tool: ShapeEditingTool?
    var startPoint: CGPoint = .zero

    init(
        shape: (ShapeWithBezierPath & ShapeWithTransform & ShapeWithBoundingRect),
        tool: ShapeEditingTool
    ) {
        self.shape = shape
        self.tool = tool
    }

    func handleDragStart(context _: ToolOperationContext, point: CGPoint) {
        startPoint = point
    }

    func handleDragContinue(context _: ToolOperationContext, point _: CGPoint, velocity _: CGPoint) {}

    func handleDragEnd(context _: ToolOperationContext, point _: CGPoint) {}

    func handleDragCancel(context _: ToolOperationContext, point _: CGPoint) {}
}

/// User is dragging the text itself to a new location
class ShapeMoveHandler: ShapeDragHandler {
    private var originalTransform: ShapeTransform

    override init(
        shape: (ShapeWithBezierPath & ShapeWithTransform & ShapeWithBoundingRect),
        tool: ShapeEditingTool
    ) {
        originalTransform = shape.transform
        super.init(shape: shape, tool: tool)
    }

    override func handleDragContinue(context _: ToolOperationContext, point: CGPoint, velocity _: CGPoint) {
        let delta = point - startPoint
        shape.transform = originalTransform.translated(by: delta)
//        tool?.updateTextView()
    }

    override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
        context.operationStack.apply(operation: ChangeTransformOperation(
            shape: shape,
            transform: originalTransform.translated(by: delta),
            originalTransform: originalTransform
        ))
    }

    override func handleDragCancel(context: ToolOperationContext, point _: CGPoint) {
        shape.transform = originalTransform
        context.toolSettings.isPersistentBufferDirty = true
//        tool?.updateShapeFrame()
    }
}

/// User is dragging the lower-right handle to change the size and rotation
/// of the text box
class ShapeResizeAndRotateHandler: ShapeDragHandler {
    private var originalTransform: ShapeTransform

    override init(
        shape: (ShapeWithBezierPath & ShapeWithTransform & ShapeWithBoundingRect),
        tool: ShapeEditingTool
    ) {
        originalTransform = shape.transform
        super.init(shape: shape, tool: tool)
    }

    private func getResizeAndRotateTransform(point: CGPoint) -> ShapeTransform {
        let originalDelta = startPoint - shape.transform.translation
        let newDelta = point - shape.transform.translation
        let originalDistance = originalDelta.length
        let newDistance = newDelta.length
        let originalAngle = atan2(originalDelta.y, originalDelta.x)
        let newAngle = atan2(newDelta.y, newDelta.x)
        let scaleChange = newDistance / originalDistance
        let angleChange = newAngle - originalAngle
        return originalTransform.scaled(by: scaleChange).rotated(by: angleChange)
    }

    override func handleDragContinue(context _: ToolOperationContext, point: CGPoint, velocity _: CGPoint) {
        shape.transform = getResizeAndRotateTransform(point: point)
//        tool?.updateTextView()
    }

    override func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        context.operationStack.apply(operation: ChangeTransformOperation(
            shape: shape,
            transform: getResizeAndRotateTransform(point: point),
            originalTransform: originalTransform
        ))
    }

    override func handleDragCancel(context: ToolOperationContext, point _: CGPoint) {
        shape.transform = originalTransform
        context.toolSettings.isPersistentBufferDirty = true
//        tool?.updateShapeFrame()
    }
}

/// User is dragging the middle-right handle to change the width of the text
/// box
class ShapeChangeWidthHandler: ShapeDragHandler {
    private var originalWidth: CGFloat?
    private var originalBoundingRect: CGRect = .zero

    override init(
        shape: (ShapeWithBezierPath & ShapeWithTransform & ShapeWithBoundingRect),
        tool: ShapeEditingTool
    ) {
        originalWidth = shape.boundingRect.width
        originalBoundingRect = shape.boundingRect
        super.init(shape: shape, tool: tool)
    }

    override func handleDragContinue(context _: ToolOperationContext, point: CGPoint, velocity _: CGPoint) {
        
    }

    override func handleDragEnd(context: ToolOperationContext, point _: CGPoint) {
        
    }

    override func handleDragCancel(context: ToolOperationContext, point _: CGPoint) {
        
    }
}
