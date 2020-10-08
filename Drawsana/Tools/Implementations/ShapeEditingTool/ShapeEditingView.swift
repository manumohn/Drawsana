//
//  ShapeEditingView.swift
//  Drawsana
//
//  Created by Manu Mohan on 21/02/20.
//

import Foundation

import UIKit

public class ShapeEditingView: UIView {
    /// Upper left 'delete' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public let deleteControlView = UIView()
    /// Lower right 'rotate' button for text. You may add any subviews you want,
    /// set border & background color, etc.
    public let resizeAndRotateControlView = UIView()
    /// Right side handle to change width of text. You may add any subviews you
    /// want, set border & background color, etc.
    public let changeWidthControlView = UIView()

    /// The `UIView` that the user interacts with during dragging
    public let selectionView: UIView

    public enum DragActionType {
        case delete
        case resizeAndRotate
        case changeWidth
    }

    public struct Control {
        public let view: UIView
        public let dragActionType: DragActionType
    }

    public private(set) var controls = [Control]()

    init(selectionView: UIView) {
        self.selectionView = selectionView
        super.init(frame: .zero)

        clipsToBounds = false
        backgroundColor = .clear
        layer.isOpaque = false

        selectionView.translatesAutoresizingMaskIntoConstraints = false

        deleteControlView.translatesAutoresizingMaskIntoConstraints = false
        deleteControlView.backgroundColor = .red

        resizeAndRotateControlView.translatesAutoresizingMaskIntoConstraints = false
        resizeAndRotateControlView.backgroundColor = .white

        changeWidthControlView.translatesAutoresizingMaskIntoConstraints = false
        changeWidthControlView.backgroundColor = .yellow

        addSubview(selectionView)

        NSLayoutConstraint.activate([
            selectionView.leftAnchor.constraint(equalTo: leftAnchor),
            selectionView.rightAnchor.constraint(equalTo: rightAnchor),
            selectionView.topAnchor.constraint(equalTo: topAnchor),
            selectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return selectionView.sizeThatFits(size)
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return selectionView.becomeFirstResponder()
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return selectionView.resignFirstResponder()
    }

    public func addStandardControls() {
        addControl(dragActionType: .delete, view: deleteControlView) { selectionView, deleteControlView in
            NSLayoutConstraint.activate(deprioritize([
                deleteControlView.widthAnchor.constraint(equalToConstant: 36),
                deleteControlView.heightAnchor.constraint(equalToConstant: 36),
                deleteControlView.rightAnchor.constraint(equalTo: selectionView.leftAnchor),
                deleteControlView.bottomAnchor.constraint(equalTo: selectionView.topAnchor, constant: -3),
            ]))
        }

        addControl(dragActionType: .resizeAndRotate, view: resizeAndRotateControlView) { selectionView, resizeAndRotateControlView in
            NSLayoutConstraint.activate(deprioritize([
                resizeAndRotateControlView.widthAnchor.constraint(equalToConstant: 36),
                resizeAndRotateControlView.heightAnchor.constraint(equalToConstant: 36),
                resizeAndRotateControlView.leftAnchor.constraint(equalTo: selectionView.rightAnchor, constant: 5),
                resizeAndRotateControlView.topAnchor.constraint(equalTo: selectionView.bottomAnchor, constant: 4),
            ]))
        }

        addControl(dragActionType: .changeWidth, view: changeWidthControlView) { selectionView, changeWidthControlView in
            NSLayoutConstraint.activate(deprioritize([
                changeWidthControlView.widthAnchor.constraint(equalToConstant: 36),
                changeWidthControlView.heightAnchor.constraint(equalToConstant: 36),
                changeWidthControlView.leftAnchor.constraint(equalTo: selectionView.rightAnchor, constant: 5),
                changeWidthControlView.bottomAnchor.constraint(equalTo: selectionView.topAnchor, constant: -4),
            ]))
        }
    }

    public func addControl<T: UIView>(dragActionType: DragActionType, view: T, applyConstraints: (UIView, T) -> Void) {
        addSubview(view)
        controls.append(Control(view: view, dragActionType: dragActionType))
        applyConstraints(selectionView, view)
    }

    public func getDragActionType(point: CGPoint) -> DragActionType? {
        guard let superview = superview else { return .none }
        for control in controls {
            if control.view.convert(control.view.bounds, to: superview).contains(point) {
                return control.dragActionType
            }
        }
        return nil
    }
}

private func deprioritize(_ constraints: [NSLayoutConstraint]) -> [NSLayoutConstraint] {
    for constraint in constraints {
        constraint.priority = .defaultLow
    }
    return constraints
}
