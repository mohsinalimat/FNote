//
//  SearchFieldCellHeader.swift
//  FNote
//
//  Created by Dara Beng on 1/25/20.
//  Copyright © 2020 Dara Beng. All rights reserved.
//

import UIKit
import Combine


class SearchFieldCellHeader: UICollectionReusableView {
    
    let searchField = UISearchTextField()
    let cancelButton = UIButton(type: .system)
    let fieldHStack = UIStackView()
    
    @Published private var debounceSearchText = ""
    private var searchTextSubscription: AnyCancellable?
    
    var searchText: String {
        set { searchField.text = newValue }
        get { searchField.text ?? "" }
    }
    
    var onCancel: (() -> Void)?
    var onSearch: (() -> Void)?
    var onSearchTextDebounced: ((String) -> Void)?
    var onSearchTextChanged: ((String) -> Void)?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
        setupTargets()
        setupSearchTextSubscription()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showCancel(_ show: Bool, animated: Bool) {
        cancelButton.isHidden = !show
        UIView.animate(withDuration: animated ? 0.3 : 0) { [weak self] in
            guard let self = self else { return }
            self.layoutIfNeeded()
        }
    }
    
    func setDebounceSearchText(_ text: String) {
        debounceSearchText = text
    }
}


extension SearchFieldCellHeader: UISearchTextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchField.resignFirstResponder()
        onSearch?()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        showCancel(true, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if searchText.trimmed().isEmpty {
            searchText = ""
            debounceSearchText = ""
            showCancel(false, animated: true)
        }
    }
}


extension SearchFieldCellHeader {
    
    private func setupView() {
        searchField.delegate = self
        searchField.placeholder = "Search"
        searchField.returnKeyType = .search
        searchField.backgroundColor = UIColor.noteCardBackground?.withAlphaComponent(0.4)
        
        cancelButton.isHidden = true
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.appAccent, for: .normal)
    }
    
    private func setupConstraints() {
        fieldHStack.addArrangedSubviews(searchField, cancelButton)
        fieldHStack.axis = .horizontal
        fieldHStack.distribution = .fill
        fieldHStack.spacing = 8
        
        addSubviews(fieldHStack, useAutoLayout: true)
        
        NSLayoutConstraint.activateConstraints(
            fieldHStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            fieldHStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            fieldHStack.widthAnchor.constraint(equalTo: widthAnchor),
            fieldHStack.heightAnchor.constraint(equalToConstant: 35)
        )
    }
    
    private func setupSearchTextSubscription() {
        searchTextSubscription = $debounceSearchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink(receiveValue: { [weak self] newValue in
                self?.onSearchTextDebounced?(newValue)
            })
    }
    
    private func setupTargets() {
        searchField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        cancelButton.addTarget(self, action: #selector(handleCancelButtonTapped), for: .touchUpInside)
    }
    
    @objc private func handleCancelButtonTapped() {
        onCancel?()
    }
    
    @objc private func handleTextChanged() {
        let text = searchField.text ?? ""
        onSearchTextChanged?(text)
        debounceSearchText = text
    }
}
