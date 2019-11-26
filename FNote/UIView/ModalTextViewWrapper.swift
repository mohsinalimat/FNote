//
//  ModalTextViewWrapper.swift
//  FNote
//
//  Created by Dara Beng on 9/15/19.
//  Copyright © 2019 Dara Beng. All rights reserved.
//

import SwiftUI


struct ModalTextViewWrapper: UIViewRepresentable {
    
    @Binding var text: String
    
    @Binding var isFirstResponder: Bool
    
    var disableEditing = false
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(wrapper: self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        context.coordinator.textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.update(with: self)
    }
    
    
    // MARK - Coordinator
    
    class Coordinator: NSObject, UITextViewDelegate, InputViewResponder {

        var wrapper: ModalTextViewWrapper
        
        let textView = UITextView()
        
        
        init(wrapper: ModalTextViewWrapper) {
            self.wrapper = wrapper
            super.init()
            setupTextView()
            listenToKeyboardNotification()
        }
        
        
        func update(with wrapper: ModalTextViewWrapper) {
            self.wrapper = wrapper
            
            textView.isEditable = !wrapper.disableEditing
            
            if !wrapper.disableEditing {
                handleFirstResponder(for: textView, isFirstResponder: wrapper.isFirstResponder)
            }
            
            if textView.text != wrapper.text {
                textView.text = wrapper.text
            }
        }
        
        func setupTextView() {
            textView.delegate = self
            textView.font = .preferredFont(forTextStyle: .body)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            wrapper.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            wrapper.isFirstResponder = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            wrapper.isFirstResponder = false
        }
        
        func listenToKeyboardNotification() {
            let center = NotificationCenter.default
            let keyboardFrameDidChange = UIResponder.keyboardDidChangeFrameNotification
            let keyboardDidHide = UIResponder.keyboardDidHideNotification
            center.addObserver(self, selector: #selector(handleKeyboardFrameChanged), name: keyboardFrameDidChange, object: nil)
            center.addObserver(self, selector: #selector(handleKeyboardDismissed), name: keyboardDidHide, object: nil)
        }
        
        @objc private func handleKeyboardFrameChanged(_ notification: Notification) {
            guard let userInfo = notification.userInfo else { return }
            guard let keyboardFrame = userInfo["UIKeyboardFrameEndUserInfoKey"] as? CGRect else { return }
            textView.contentInset.bottom = keyboardFrame.height
            textView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
        }
        
        @objc private func handleKeyboardDismissed(_ notification: Notification) {
            UIView.animate(withDuration: 0.4) { [weak self] in
                guard let self = self else { return }
                self.textView.contentInset.bottom = 0
                self.textView.verticalScrollIndicatorInsets.bottom = 0
            }
        }
    }
}
