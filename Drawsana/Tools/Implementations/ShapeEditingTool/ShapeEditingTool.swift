//
//  ShapeEditingView.swift
//  Drawsana
//
//  Created by Manu Mohan on 21/02/20.
//

import Foundation

public class ShapeEditingTool: DrawingTool {
    public var isProgressive: Bool { return false }
    
    public var name: String = "ShapeEditor"
    
    /// You may set yourself as the delegate to be notified when special selection
    /// events happen that you might want to react to. The core framework does
    /// not use this delegate.
    public weak var delegate: SelectionToolDelegate?

    private var originalTransform: ShapeTransform?
    private var startPoint: CGPoint?
    /* When you tap away from a shape you've just dragged, the method calls look
     like this:
      - handleDragStart (hitTest on selectedShape fails)
      - handleDragContinue
      - handleDragCancel
      - handleTap

     We need to be careful not to incorrectly reset the transform for the selected
     shape when you tap away, so we explicitly capture whether you are actually
     dragging the shape or not.
     */
    private var isDraggingShape = false

    private var isUpdatingSelection = false

    // MARK: Internal state

    /// The text tool has 3 different behaviors on drag depending on where your
    /// touch starts. See `DragHandler.swift` for their implementations.
    private var dragHandler: ShapeDragHandler?
    
    // internal for use by DragHandler subclasses
    internal var editingView: ShapeEditingView = ShapeEditingView(selectionView: UIView())
    
    public init(delegate: SelectionToolDelegate? = nil) {
        self.delegate = delegate
    }
    
    public func deactivate(context: ToolOperationContext) {
        context.toolSettings.selectedShape = nil
    }

    public func apply(context: ToolOperationContext, userSettings: UserSettings) {
        if let shape = context.toolSettings.selectedShape {
            if isUpdatingSelection {
                if let shapeWithStandardState = shape as? ShapeWithStandardState {
                    context.userSettings.fillColor = shapeWithStandardState.fillColor
                    context.userSettings.strokeColor = shapeWithStandardState.strokeColor
                    context.userSettings.strokeWidth = shapeWithStandardState.strokeWidth
                } else if let shapeWithStrokeState = shape as? ShapeWithStrokeState {
                    context.userSettings.strokeColor = shapeWithStrokeState.strokeColor
                    context.userSettings.strokeWidth = shapeWithStrokeState.strokeWidth
                }
            } else {
                shape.apply(userSettings: userSettings)
                context.toolSettings.isPersistentBufferDirty = true
            }
        }
        
        if let selectionView = context.toolSettings.selectionView {
            self.editingView = ShapeEditingView(selectionView: selectionView)
            editingView.addStandardControls()
            context.toolSettings.interactiveView = editingView
        }
    }

}

extension ShapeEditingTool {
    public func handleTap(context: ToolOperationContext, point: CGPoint) {
        if let selectedShape = context.toolSettings.selectedShape, selectedShape.hitTest(point: point) == true {
            if let delegate = delegate {
                delegate.selectionToolDidTapOnAlreadySelectedShape(selectedShape)
            } else {
                // Default behavior: deselect the shape
                context.toolSettings.selectedShape = nil
            }
            return
        } else {
            context.toolSettings.selectedShape = nil
            handleTapWhenNoShapeIsActive(context: context, point: point)
        }

        updateSelection(context: context, context.drawing.shapes
            .compactMap { $0 as? ShapeSelectable }
            .filter { $0.hitTest(point: point) }
            .last)
    }
    
    private func handleTapWhenShapeIsActive(context: ToolOperationContext, point: CGPoint, shape: TextShape) {
        //do stuff like delete and delegating back to draign view
        return
    }

    private func handleTapWhenNoShapeIsActive(context: ToolOperationContext, point: CGPoint) {
        if let tappedShape = context.drawing.getShape(of: RectShape.self, at: point) {
            context.toolSettings.selectedShape = tappedShape
            context.toolSettings.isPersistentBufferDirty = true
        }
    }

    public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
        guard let selectedShape = context.toolSettings.selectedShape as? (ShapeWithBezierPath & ShapeWithTransform & ShapeWithBoundingRect), selectedShape.hitTest(point: point) else {
            isDraggingShape = false
            return
        }
        
        if let dragActionType = editingView.getDragActionType(point: point), case .resizeAndRotate = dragActionType {
            dragHandler = ShapeResizeAndRotateHandler(shape: selectedShape, tool: self)
        } else if let dragActionType = editingView.getDragActionType(point: point), case .changeWidth = dragActionType {
            dragHandler = ShapeChangeWidthHandler(shape: selectedShape, tool: self)
        } else if selectedShape.hitTest(point: point) {
            dragHandler = ShapeMoveHandler(shape: selectedShape, tool: self)
        } else {
            dragHandler = nil
        }

        if let dragHandler = dragHandler {
//            applyEditTextOperationIfTextHasChanged(context: context)
            dragHandler.handleDragStart(context: context, point: point)
        }
        
        isDraggingShape = true
        originalTransform = selectedShape.transform
        startPoint = point
    }

    public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
        if let dragHandler = dragHandler {
            dragHandler.handleDragContinue(context: context, point: point, velocity: velocity)
        } else {
            // The pan gesture is super finicky at the start, so add an affordance for
            // dragging over a handle
            switch editingView.getDragActionType(point: point) {
            case .some(.resizeAndRotate), .some(.changeWidth):
                handleDragStart(context: context, point: point)
            default: break
            }
        }
    }

    public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
        if let dragHandler = dragHandler {
            dragHandler.handleDragEnd(context: context, point: point)
            self.dragHandler = nil
        }
    }

    public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
        if let dragHandler = dragHandler {
            dragHandler.handleDragCancel(context: context, point: point)
            self.dragHandler = nil
        }
    }
    
    /// Update selection on context.toolSettings, but make sure that when apply()
    /// is called as a part of that change, we don't immediately change the
    /// properties of the newly selected shape.
    private func updateSelection(context: ToolOperationContext, _ newSelectedShape: ShapeSelectable?) {
        isUpdatingSelection = true
        context.toolSettings.selectedShape = newSelectedShape
        isUpdatingSelection = false
    }
}
